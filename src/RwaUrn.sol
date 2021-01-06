pragma solidity 0.5.12;

import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dapp/DSTokenAbstract.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/DaiJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/DaiAbstract.sol";

contract RwaUrn {
    // --- auth ---
    mapping (address => uint256) public wards;
    mapping (address => uint256) public can;
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }
    modifier auth {
        require(wards[msg.sender] == 1, "RwaUrn/not-authorized");
        _;
    }
    function hope(address usr) external auth {
        can[usr] = 1;
        emit Hope(usr);
    }
    function nope(address usr) external auth {
        can[usr] = 0;
        emit Nope(usr);
    }
    modifier operator {
        require(can[msg.sender] == 1, "RwaUrn/not-operator");
        _;
    }

    VatAbstract  public vat;
    GemJoinAbstract public gemJoin;
    DaiJoinAbstract public daiJoin;
    address public fbo;              // routing conduit

    // Events
    event Rely(address usr);
    event Deny(address usr);
    event Hope(address usr);
    event Nope(address usr);
    event File(bytes32 what, address data);
    event Lock(uint256 wad);
    event Free(uint256 wad);
    event Draw(uint256 wad);
    event Wipe(uint256 wad);

    // --- init ---
    constructor(
        address vat_, address gemJoin_, address daiJoin_, address fbo_
    ) public {
        // requires in urn that fbo isn't address(0)
        vat = VatAbstract(vat_);
        gemJoin = GemJoinAbstract(gemJoin_);
        daiJoin = DaiJoinAbstract(daiJoin_);
        fbo = fbo_;
        wards[msg.sender] = 1;
        DSTokenAbstract(gemJoin.gem()).approve(address(gemJoin), uint256(-1));
        DaiAbstract(daiJoin.dai()).approve(address(daiJoin), uint256(-1));
        VatAbstract(vat_).hope(address(daiJoin));
        emit Rely(msg.sender);
    }

    // --- administration ---
    function file(bytes32 what, address data) external auth {
        // add require statement ensuring address != 0
        if (what == "fbo") {
            fbo = data;
            emit File(what, data);
        }
        else revert("RwaUrn/unrecognised-param");
    }

    // --- cdp operation ---
    // n.b. DAI can only go to fbo
    function lock(uint256 wad) external operator {
        DSTokenAbstract(gemJoin.gem()).transferFrom(address(msg.sender), address(this), wad);
        // join with address this
        gemJoin.join(address(this), wad);
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), int(wad), 0);
        emit Lock(wad);
    }
    function free(uint256 wad) external operator {
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), -int(wad), 0);
        gemJoin.exit(address(this), wad);
        DSTokenAbstract(gemJoin.gem()).transfer(address(msg.sender), wad);
        emit Free(wad);
    }
    function draw(uint256 wad) external operator {
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), 0, int(wad));
        daiJoin.exit(fbo, wad);
        emit Draw(wad);
    }
    function wipe(uint256 wad) external operator {
        daiJoin.join(address(this), wad);
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), 0, -int(wad));
        emit Wipe(wad);
    }
}
