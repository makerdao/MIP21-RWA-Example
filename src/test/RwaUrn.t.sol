// SPDX-License-Identifier: AGPL-3.0-or-later
//
// RwaUrn.t.sol -- Tests for the Urn contract
//
// Copyright (C) 2020-2021 Lev Livnev <lev@liv.nev.org.uk>
// Copyright (C) 2021-2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ~0.6.12;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-math/math.sol";

import {Vat} from "dss/vat.sol";
import {Jug} from 'dss/jug.sol';
import {Spotter} from "dss/spot.sol";

import {DaiJoin} from 'dss/join.sol';
import {AuthGemJoin} from "dss-gem-joins/join-auth.sol";

import {RwaToken} from "../RwaToken.sol";
import {RwaInputConduit, RwaOutputConduit} from "../RwaConduit.sol";
import {RwaLiquidationOracle} from "../RwaLiquidationOracle.sol";
import {RwaUrn} from "../RwaUrn.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

contract RwaUltimateRecipient {
    DSToken dai;
    constructor(DSToken dai_) public {
        dai = dai_;
    }
    function transfer(address who, uint256 wad) public {
        dai.transfer(who, wad);
    }
}

contract TryCaller {
    function do_call(address addr, bytes calldata data) external returns (bool) {
        bytes memory _data = data;
        assembly {
            let ok := call(gas(), addr, 0, add(_data, 0x20), mload(_data), 0, 0)
            let free := mload(0x40)
            mstore(free, ok)
            mstore(0x40, add(free, 32))
            revert(free, 32)
        }
    }

    function try_call(address addr, bytes calldata data) external returns (bool ok) {
        (, bytes memory returned) = address(this).call(abi.encodeWithSignature("do_call(address,bytes)", addr, data));
        ok = abi.decode(returned, (bool));
    }
}

contract RwaUser is TryCaller {
    RwaUrn urn;
    RwaOutputConduit outC;
    RwaInputConduit inC;

    constructor(RwaUrn urn_, RwaOutputConduit outC_, RwaInputConduit inC_)
        public {
        urn = urn_;
        outC = outC_;
        inC = inC_;
    }

    function approve(RwaToken tok, address who, uint256 wad) public {
        tok.approve(who, wad);
    }
    function pick(address who) public {
        outC.pick(who);
    }
    function lock(uint256 wad) public {
        urn.lock(wad);
    }
    function free(uint256 wad) public {
        urn.free(wad);
    }
    function draw(uint256 wad) public {
        urn.draw(wad);
    }
    function wipe(uint256 wad) public {
        urn.wipe(wad);
    }
    function can_pick(address who) public returns (bool ok) {
        ok = this.try_call(
            address(outC),
            abi.encodeWithSignature("pick(address)", who)
        );
    }
    function can_draw(uint256 wad) public returns (bool ok) {
        ok = this.try_call(
            address(urn),
            abi.encodeWithSignature("draw(uint256)", wad)
        );
    }
    function can_free(uint256 wad) public returns (bool ok) {
        ok = this.try_call(
            address(urn),
            abi.encodeWithSignature("free(uint256)", wad)
        );
    }
}

contract TryPusher is TryCaller {
    function can_push(address wat) public returns (bool ok) {
        ok = this.try_call(
            address(wat),
            abi.encodeWithSignature("push()")
        );
    }
}

contract RwaExampleTest is DSTest, DSMath, TryPusher {
    Hevm hevm;

    DSToken gov;
    DSToken dai;
    RwaToken rwa;

    Vat vat;
    Jug jug;
    address vow = address(123);
    Spotter spotter;

    DaiJoin daiJoin;
    AuthGemJoin gemJoin;

    RwaLiquidationOracle oracle;
    RwaUrn urn;

    RwaOutputConduit outConduit;
    RwaInputConduit inConduit;

    RwaUser usr;
    RwaUltimateRecipient rec;

    // debt ceiling of 400 dai
    uint256 ceiling = 400 ether;
    string doc = "Please sign on the dotted line.";

    string  public constant name     = "RWA-001";
    string  public constant symbol   = "RWA001";

    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }
    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        // deploy governance token
        gov = new DSToken('GOV');
        gov.mint(100 ether);

        // deploy rwa token
        rwa = new RwaToken(name, symbol);

        // standard Vat setup
        vat = new Vat();

        jug = new Jug(address(vat));
        jug.file("vow", address(vow));
        vat.rely(address(jug));

        spotter = new Spotter(address(vat));
        vat.rely(address(spotter));

        dai = new DSToken("Dai");
        daiJoin = new DaiJoin(address(vat), address(dai));
        vat.rely(address(daiJoin));
        dai.setOwner(address(daiJoin));

        // the first RWA ilk is Acme Real World Assets Corporation
        vat.init("acme");
        vat.file("Line", 100 * rad(ceiling));
        vat.file("acme", "line", rad(ceiling));

        jug.init("acme");
        // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
        uint256 EIGHT_PCT = 1000000002440418608258400030;
        jug.file("acme", "duty", EIGHT_PCT);

        oracle = new RwaLiquidationOracle(address(vat), vow);
        oracle.init(
            "acme",
            wmul(ceiling, 1.1 ether),
            doc,
            2 weeks);
        vat.rely(address(oracle));
        (,address pip,,) = oracle.ilks("acme");

        spotter.file("acme", "mat", RAY);
        spotter.file("acme", "pip", pip);
        spotter.poke("acme");

        gemJoin = new AuthGemJoin(address(vat), "acme", address(rwa));
        vat.rely(address(gemJoin));

        // deploy output dai conduit
        outConduit = new RwaOutputConduit(address(gov), address(dai));
        // deploy urn
        urn = new RwaUrn(address(vat), address(jug), address(gemJoin), address(daiJoin), address(outConduit));
        gemJoin.rely(address(urn));
        // deploy input dai conduit, pointed permanently at the urn
        inConduit = new RwaInputConduit(address(gov), address(dai), address(urn));

        // deploy user and ultimate dai recipient
        usr = new RwaUser(urn, outConduit, inConduit);
        rec = new RwaUltimateRecipient(dai);

        // fund user with rwa
        rwa.transfer(address(usr), 1 ether);

        // auth user to operate
        urn.hope(address(usr));
        outConduit.hope(address(usr));
        outConduit.kiss(address(rec));

        usr.approve(rwa, address(urn), uint(-1));
    }

    function test_file() public {
        urn.file("outputConduit", address(123));
        assertEq(urn.outputConduit(), address(123));
        urn.file("jug", address(456));
        assertEq(address(urn.jug()), address(456));
    }

    function test_unpick_and_pick_new_rec() public {
        // lock some acme and draw some dai
        usr.lock(1 ether);
        usr.draw(400 ether);

        // usr nominates ultimate recipient
        usr.pick(address(rec));
        // the dai can be pushed
        assertTrue(can_push(address(outConduit)));

        // unpick current rec
        usr.pick(address(0));

        // dai can't move
        assertTrue(! can_push(address(outConduit)));

        // deploy and whitelist new rec
        RwaUltimateRecipient newrec = new RwaUltimateRecipient(dai);
        outConduit.kiss(address(newrec));

        usr.pick(address(newrec));
        outConduit.push();

        assertEq(dai.balanceOf(address(newrec)), 400 ether);
    }

    function test_cant_pick_unkissed_rec() public {
        RwaUltimateRecipient newrec = new RwaUltimateRecipient(dai);
        assertTrue(! usr.can_pick(address(newrec)));
    }

    function test_lock_and_draw() public {
        // check initial balances
        assertEq(dai.balanceOf(address(outConduit)), 0);
        assertEq(dai.balanceOf(address(rec)), 0);

        hevm.warp(now + 10 days); // Let rate be > 1

        assertEq(vat.dai(address(urn)), 0);

        (uint256 ink, uint256 art) = vat.urns("acme", address(urn));
        assertEq(ink, 0);
        assertEq(art, 0);

        usr.lock(1 ether);
        usr.draw(399 ether); // with 400 will fail due vat ceiling (rounding)

        assertEq(vat.dai(address(urn)), 463899466724981907732616508); // dust from divup

        (, uint256 rate,,,) = vat.ilks("acme");
        (ink, art) = vat.urns("acme", address(urn));
        assertEq(ink, 1 ether);
        assertEq(art, (rad(399 ether) + 463899466724981907732616508) / rate);

        // check the amount went to the output conduit
        assertEq(dai.balanceOf(address(outConduit)), 399 ether);
        assertEq(dai.balanceOf(address(rec)), 0);

        // usr nominates ultimate recipient
        usr.pick(address(rec));
        // push the amount to the receiver
        outConduit.push();
        assertEq(dai.balanceOf(address(outConduit)), 0);
        assertEq(dai.balanceOf(address(rec)), 399 ether);
    }

    function test_draw_exceeds_debt_ceiling() public {
        usr.lock(1 ether);
        assertTrue(! usr.can_draw(500 ether));
    }

    function test_cant_draw_unless_hoped() public {
        usr.lock(1 ether);

        RwaUser rando = new RwaUser(urn, outConduit, inConduit);
        assertTrue(! rando.can_draw(100 ether));

        urn.hope(address(rando));
        assertEq(dai.balanceOf(address(outConduit)), 0);
        rando.draw(100 ether);
        assertEq(dai.balanceOf(address(outConduit)), 100 ether);
    }

    function test_partial_repay() public {
        usr.lock(1 ether);
        usr.draw(400 ether);

        // usr nominates ultimate recipient
        usr.pick(address(rec));
        outConduit.push();

        hevm.warp(now + 30 days);

        rec.transfer(address(inConduit), 100 ether);
        assertEq(dai.balanceOf(address(inConduit)), 100 ether);

        inConduit.push();
        usr.wipe(100 ether);
        assertTrue(! usr.can_free(1 ether));
        usr.free(0.1 ether);

        (uint ink, uint art) = vat.urns("acme", address(urn));
        // > 300 because of accumulated interest
        assertTrue(art > 300 ether);
        assertTrue(art < 301 ether);
        assertEq(ink, 0.9 ether);
        assertEq(dai.balanceOf(address(inConduit)), 0 ether);
    }

    function test_partial_repay_fuzz(uint256 drawAmount, uint256 wipeAmount, uint256 drawTime, uint256 wipeTime) public {
        // Convert to reasonable numbers
        drawAmount = (drawAmount % 300 ether) + 100 ether;      // 100-400 ether
        wipeAmount = wipeAmount % drawAmount;                   // 0-drawAmount ether
        drawTime = drawTime % 15 days;                       // 0-15 days
        wipeTime = wipeTime % 15 days;                       // 0-15 days

        usr.lock(1 ether);

        hevm.warp(now + drawTime);
        jug.drip("acme");

        usr.draw(drawAmount);

        // usr nominates ultimate recipient
        usr.pick(address(rec));
        outConduit.push();

        hevm.warp(now + wipeTime);
        jug.drip("acme");

        rec.transfer(address(inConduit), wipeAmount);
        assertEq(dai.balanceOf(address(inConduit)), wipeAmount);

        inConduit.push();
        usr.wipe(wipeAmount);
    }

    function test_repay_rounding_fuzz(uint256 drawAmt, uint256 drawTime, uint256 wipeTime) public {
        // Convert to reasonable numbers
        drawAmt = (drawAmt % 300 ether) + 99.99 ether; // 99.99-399.99 ether
        drawTime = drawTime % 15 days;                       // 0-15 days
        wipeTime = wipeTime % 15 days;                       // 0-15 days

        (uint256 ink, uint256 art) = vat.urns("acme", address(urn));
        assertEq(ink, 0);
        assertEq(art, 0);

        usr.lock(1 ether);

        hevm.warp(now + drawTime);
        jug.drip("acme");

        usr.draw(drawAmt);

        uint256 urnVatDust = vat.dai(address(urn));

        // A draw should leave less than 2 RAY dust
        assertTrue(urnVatDust < 2 * RAY);

        (, uint256 rate,,,) = vat.ilks("acme");
        (ink, art) = vat.urns("acme", address(urn));
        assertEq(ink, 1 ether);
        assertEq(art, (rad(drawAmt) + urnVatDust) / rate);

        // usr nominates ultimate recipient
        usr.pick(address(rec));
        outConduit.push();

        hevm.warp(now + wipeTime);
        jug.drip("acme");

        (, rate,,,) = vat.ilks("acme");

        uint256 fullWipeAmt = art * rate / RAY;
        if (fullWipeAmt * RAY < art * rate) {
            fullWipeAmt += 1;
        }

        // Forcing extra DAI balance to pay accumulated fee
        hevm.store(
            address(dai),
            keccak256(abi.encode(address(rec), uint256(3))),
            bytes32(uint256(fullWipeAmt))
        );
        hevm.store(
            address(dai),
            bytes32(uint256(2)),
            bytes32(uint256(fullWipeAmt))
        );
        hevm.store(
            address(vat),
            keccak256(abi.encode(address(daiJoin), uint256(5))),
            bytes32(uint256(fullWipeAmt * RAY))
        );
        //

        rec.transfer(address(inConduit), fullWipeAmt);
        assertEq(dai.balanceOf(address(inConduit)), fullWipeAmt);

        inConduit.push();
        usr.wipe(fullWipeAmt);

        (, art) = vat.urns("acme", address(urn));
        assertEq(art, 0);

        uint256 newUrnVatDust = vat.dai(address(urn));
        // A wipe should leave less than 1 RAY dust
        assertTrue(newUrnVatDust - urnVatDust < RAY);
    }

    function test_full_repay() public {
        usr.lock(1 ether);
        usr.draw(400 ether);

        // usr nominates ultimate recipient
        usr.pick(address(rec));
        outConduit.push();

        rec.transfer(address(inConduit), 400 ether);

        inConduit.push();
        usr.wipe(400 ether);
        usr.free(1 ether);

        (uint ink, uint art) = vat.urns("acme", address(urn));
        assertEq(art, 0);
        assertEq(ink, 0);
        assertEq(rwa.balanceOf(address(usr)), 1 ether);
    }

    function test_oracle_cure() public {
        usr.lock(1 ether);
        assertTrue(usr.can_draw(10 ether));

        // flash the liquidation beacon
        vat.file("acme", "line", rad(0));
        oracle.tell("acme");

        // not able to borrow
        assertTrue(! usr.can_draw(10 ether));

        hevm.warp(block.timestamp + 1 weeks);

        oracle.cure("acme");
        vat.file("acme", "line", rad(ceiling));
        assertTrue(oracle.good("acme"));

        // able to borrow
        assertEq(dai.balanceOf(address(rec)), 0);
        usr.draw(100 ether);
        // usr nominates ultimate recipient
        usr.pick(address(rec));
        outConduit.push();
        assertEq(dai.balanceOf(address(rec)), 100 ether);
    }

    function testFail_oracle_cure_unknown_ilk() public {
        // unknown ilk ecma
        oracle.cure("ecma");
    }

    function testFail_oracle_cure_not_in_remediation() public {
        oracle.cure("acme");
    }

    function testFail_oracle_cure_not_in_remediation_anymore() public {
        usr.lock(1 ether);
        assertTrue(usr.can_draw(10 ether));

        // flash the liquidation beacon
        vat.file("acme", "line", rad(0));
        oracle.tell("acme");

        // not able to borrow
        assertTrue(! usr.can_draw(10 ether));

        hevm.warp(block.timestamp + 1 weeks);

        oracle.cure("acme");
        vat.file("acme", "line", rad(ceiling));
        assertTrue(oracle.good("acme"));

        // able to borrow
        assertEq(dai.balanceOf(address(rec)), 0);
        usr.draw(100 ether);
        // usr nominates ultimate recipient
        usr.pick(address(rec));
        outConduit.push();
        assertEq(dai.balanceOf(address(rec)), 100 ether);
        oracle.cure("acme");
    }

    function test_oracle_cull() public {
        usr.lock(1 ether);
        // not at full utilisation
        usr.draw(200 ether);

        // flash the liquidation beacon
        vat.file("acme", "line", rad(0));
        oracle.tell("acme");

        // not able to borrow
        assertTrue(! usr.can_draw(10 ether));

        hevm.warp(block.timestamp + 1 weeks);
        // still in remeditation period
        assertTrue(oracle.good("acme"));

        hevm.warp(block.timestamp + 2 weeks);

        assertEq(vat.gem("acme", address(oracle)), 0);
        // remediation period has elapsed
        assertTrue(! oracle.good("acme"));
        oracle.cull("acme", address(urn));

        assertTrue(! usr.can_draw(10 ether));

        (uint ink, uint art) = vat.urns("acme", address(urn));
        assertEq(ink, 0);
        assertEq(art, 0);

        assertEq(vat.sin(vow), rad(200 ether));

        // after the write-off, the gem goes to the oracle
        assertEq(vat.gem("acme", address(oracle)), 1 ether);

        spotter.poke("acme");
        (,,uint256 spot ,,) = vat.ilks("acme");
        assertEq(spot, 0);
    }

    function test_oracle_unremedied_loan_is_not_good() public {
        usr.lock(1 ether);
        usr.draw(200 ether);

        vat.file("acme", "line", 0);
        oracle.tell("acme");
        assertTrue(oracle.good("acme"));

        hevm.warp(block.timestamp + 3 weeks);
        assertTrue(! oracle.good("acme"));
    }

    function test_oracle_cull_two_urns() public {
        RwaUrn urn2 = new RwaUrn(
            address(vat),
            address(jug),
            address(gemJoin),
            address(daiJoin),
            address(outConduit)
        );
        gemJoin.rely(address(urn2));
        RwaUser usr2 = new RwaUser(urn2, outConduit, inConduit);
        usr.approve(rwa, address(this), uint(-1));
        rwa.transferFrom(address(usr), address(usr2), 0.5 ether);
        usr2.approve(rwa, address(urn2), uint(-1));
        urn2.hope(address(usr2));
        usr.lock(0.5 ether);
        usr2.lock(0.5 ether);
        usr.draw(100 ether);
        usr2.draw(100 ether);

        assertTrue(usr.can_draw(1 ether));
        assertTrue(usr2.can_draw(1 ether));

        vat.file("acme", "line", 0);
        oracle.tell("acme");

        assertTrue(! usr.can_draw(1 ether));
        assertTrue(! usr2.can_draw(1 ether));

        hevm.warp(block.timestamp + 3 weeks);

        oracle.cull("acme", address(urn));
        assertEq(vat.sin(vow), rad(100 ether));
        oracle.cull("acme", address(urn2));
        assertEq(vat.sin(vow), rad(200 ether));
    }

    function test_oracle_bump() public {
        usr.lock(1 ether);
        usr.draw(400 ether);

        // usr nominates ultimate recipient
        usr.pick(address(rec));
        outConduit.push();

        // can't borrow more, ceiling exceeded
        assertTrue(! usr.can_draw(1 ether));

        // increase ceiling by 200 dai
        vat.file("acme", "line", rad(ceiling + 200 ether));

        // still can't borrow much more, vault is unsafe
        assertTrue(usr.can_draw(1 ether));
        assertTrue(! usr.can_draw(200 ether));

        // bump the price of acme
        oracle.bump("acme", wmul(ceiling + 200 ether, 1.1 ether));
        spotter.poke("acme");

        usr.draw(200 ether);
        // recipient must be picked again for 2nd push
        usr.pick(address(rec));
        outConduit.push();

        assertEq(dai.balanceOf(address(rec)), 600 ether);
    }

    function testFail_oracle_bump_unknown_ilk() public {
        // unknown ilk ecma
        oracle.bump("ecma", wmul(ceiling + 200 ether, 1.1 ether));
    }

    function testFail_oracle_bump_in_remediation() public {
        vat.file("acme", "line", 0);
        oracle.tell("acme");
        oracle.bump("acme", wmul(ceiling + 200 ether, 1.1 ether));
    }

    function test_quit() public {
        usr.lock(1 ether);
        usr.draw(400 ether);

        // usr nominates ultimate recipient
        usr.pick(address(rec));
        outConduit.push();

        rec.transfer(address(inConduit), 400 ether);

        inConduit.push();
        vat.cage();
        assertEq(dai.balanceOf(address(urn)), 400 ether);
        assertEq(dai.balanceOf(address(outConduit)), 0);
        urn.quit();
        assertEq(dai.balanceOf(address(urn)), 0);
        assertEq(dai.balanceOf(address(outConduit)), 400 ether);
    }

    function testFail_quit() public {
        usr.lock(1 ether);
        usr.draw(400 ether);

        // usr nominates ultimate recipient
        usr.pick(address(rec));
        outConduit.push();

        rec.transfer(address(inConduit), 400 ether);

        inConduit.push();
        urn.quit();
    }
}
