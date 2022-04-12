/* prettier-disable */

/**
 * This file is a copy of https://goerli.etherscan.io/address/0xeb7C7DE82c3b05BD4059f11aE8f43dD7f1595bce#code.
 * The only change is the solidity version, since this repo is using 0.6.x
 */

////// src/RwaToken.sol
// Copyright (C) 2020, 2021 Lev Livnev <lev@liv.nev.org.uk>
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.8 <0.7.0;

import {DSTest} from "ds-test/test.sol";
import {ForwardProxy} from "forward-proxy/ForwardProxy.sol";

import {RwaToken} from "./RwaToken.sol";
import {RwaTokenFactory} from "./RwaTokenFactory.sol";

contract RwaTokenFactoryTest is DSTest {
    uint256 constant WAD = 10 ** 18;

    ForwardProxy op;
    ForwardProxy recipient;
    RwaTokenFactory tokenFactory;
    string name = "RWA001-Test";
    string symbol = "RWA001";

    function setUp() public {
        op = new ForwardProxy();
        recipient = new ForwardProxy();
        tokenFactory = new RwaTokenFactory(address(op));
    }

    function test_authSet() public {
        assertEq(tokenFactory.wards(address(op)), 1);
    }

    function testFail_dsPauseRequireForFactoryDeploy() public {
        new RwaTokenFactory(address(0));
    }

    function testFail_failOnNotAuthorized() public {
        tokenFactory.createRwaToken(name, symbol, address(this));
    }

    function testFail_NameAndSymbolRequired() public {
        RwaTokenFactory(op._(address(tokenFactory))).createRwaToken("", "", address(this));
    }

    function testFail_RecipientRequired() public {
        RwaTokenFactory(op._(address(tokenFactory))).createRwaToken(name, symbol, address(0));
    }

    function testFail_failOnAlreadyExistSymbol() public {
        RwaToken token = RwaTokenFactory(op._(address(tokenFactory))).createRwaToken(name, symbol, address(recipient));
        assertTrue(address(token) != address(0));
        RwaTokenFactory(op._(address(tokenFactory))).createRwaToken(name, symbol, address(recipient));
    }

    function test_canCreateRwaToken() public {
        RwaToken token = RwaTokenFactory(op._(address(tokenFactory))).createRwaToken(name, symbol, address(recipient));
        assertTrue(address(token) != address(0));
        assertEq(token.balanceOf(address(recipient)), 1 * WAD);
    }

    function test_canGetRegistry() public {
        RwaToken token = RwaTokenFactory(op._(address(tokenFactory))).createRwaToken(name, symbol, address(recipient));
        assertTrue(address(token) != address(0));
        bytes32[1] memory tokens = [tokenFactory.stringToBytes32(symbol)];
        bytes32[] memory tokensFromFactory = tokenFactory.list();
        assertEq(tokenFactory.count(), tokens.length);
        assertEq(tokensFromFactory[0], tokens[0]);
    }
}
