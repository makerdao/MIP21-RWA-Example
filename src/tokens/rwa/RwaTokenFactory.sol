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

import {RwaToken} from "./RwaToken.sol";

contract RwaTokenFactory {
    // --- registry ---
    mapping (bytes32 => bool) public tokensData;
    bytes32[] tokens;

    // --- auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "RwaTokenFactory/not-authorized");
        _;
    }

    // Events
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    // --- math ---
    uint256 constant WAD = 10**18;

    // --- init ---
    constructor(
        address dsPause
    ) public {
        require(dsPause != address(0), "RwaTokenFactory/ds-pause-not-set");
        wards[dsPause] = 1;
        emit Rely(dsPause);
    }

    // The number of deployed tokens
    function count() external view returns (uint256) {
        return tokens.length;
    }

    // Return an array of the deployed tokens
    function list() external view returns (bytes32[] memory) {
        return tokens;
    }

    function createRwaToken(string calldata name, string calldata symbol, address recipient) public auth  returns (RwaToken) {
        require(recipient != address(0), "RwaTokenFactory/recipient-not-set");
        require(bytes(name).length != 0, "RwaTokenFactory/name-not-set");
        require(bytes(symbol).length != 0, "RwaTokenFactory/symbol-not-set");
        bytes32 _symbol = stringToBytes32(symbol);
        require(!tokensData[_symbol], "RwaTokenFactory/symbol-already-exist");

        RwaToken token = new RwaToken(name, symbol);
        token.transfer(recipient, 1 * WAD);
        tokensData[_symbol] = true;
        tokens.push(_symbol);
        return token;
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}
