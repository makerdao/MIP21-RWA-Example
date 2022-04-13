/* prettier-disable */
// Copyright (C) 2022 Dai Foundation
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
pragma solidity 0.6.12;

import {RwaToken} from "./RwaToken.sol";

contract RwaTokenFactory {
    // --- registry ---
    mapping (bytes32 => address) public tokensData;
    bytes32[] tokens;

    // --- auth ---
    mapping(address => uint256) public wards;

    // -- events --
    event RwaTokenCreated(string name, string indexed symbol, address indexed recipient);

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
        bytes32 _symbol = this.stringToBytes32(symbol);
        require(tokensData[_symbol] == address(0), "RwaTokenFactory/symbol-already-exist");

        RwaToken token = new RwaToken(name, symbol);
        token.transfer(recipient, 1 * WAD);
        tokensData[_symbol] = address(token);
        tokens.push(_symbol);

        emit RwaTokenCreated(name, symbol, address(token));
        return token;
    }

    function stringToBytes32(string memory source) external pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}
