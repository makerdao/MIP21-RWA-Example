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
import {RwaToken} from "./RwaToken.sol";

contract RwaTokenTest is DSTest {
    uint256 constant WAD = 10**18;

    RwaToken token;
    uint256 expectedTokensMinted = 1 * WAD;
    string name = "RWA001-Test";
    string symbol = "RWA001";

    function setUp() public {
        token = new RwaToken(name, symbol);
    }

    function test_tokenAndSymbol() public {
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
    }

    function test_totalSupplyHardcoded() public {
        assertEq(token.totalSupply(), expectedTokensMinted);
    }

    function test_tokenMinted() public {
        assertEq(token.balanceOf(address(this)), expectedTokensMinted);
    }
}
