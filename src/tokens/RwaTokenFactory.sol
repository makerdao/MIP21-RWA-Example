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

/**
 * @author Nazar Duchak <nazar@clio.finance>
 * @title An Factory for RWA Token.
 */
contract RwaTokenFactory {
    /// @notice registry for RWA tokens (symbol => tokenAddress).
    uint256 constant WAD = 10**18;

    /// @notice registry for RWA tokens (symbol => tokenAddress).
    mapping (bytes32 => address) public tokensData;
    /// @notice list of created RWA token symbols.
    bytes32[] public tokens;
    /// @notice Addresses with admin access on this contract. `wards[usr]`
    mapping(address => uint256) public wards;


    /**
     * @notice `usr` was granted admin access.
     * @param usr The user address.
     */
    event Rely(address indexed usr);
    /**
     * @notice `usr` admin access was revoked.
     * @param usr The user address.
     */
    event Deny(address indexed usr);
    /**
     * @notice RWA Token created.
     * @param name Token name.
     * @param symbol Token symbol.
     * @param recipient Token address recipient.
     */
    event RwaTokenCreated(string name, string indexed symbol, address indexed recipient);

    /**
     * @notice Check if `msg.sender` have admin access.
     */
    modifier auth() {
        require(wards[msg.sender] == 1, "RwaTokenFactory/not-authorized");
        _;
    }

    /**
     * @notice Gives `dsPause` admin access.
     * @param dsPause DsPause contract address.
     */
    constructor(
        address dsPause
    ) public {
        require(dsPause != address(0), "RwaTokenFactory/ds-pause-not-set");
        wards[dsPause] = 1;
        emit Rely(dsPause);
    }

    /**
     * @notice Grants `usr` admin access to this contract.
     * @param usr The user address.
     */
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    /**
     * @notice Revokes `usr` admin access from this contract.
     * @param usr The user address.
     */
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    /**
     * @notice Deploy an RWA Token and mint `1 * WAD` to recipient address.
     * @dev Only addresses with admin access(wards[msg.sender]) are able call this function
     * @dev History of created tokens are stored in `tokenData` which is publicly accessible
     * @param name Token name.
     * @param symbol Token symbol.
     * @param recipient Recipient address.
     */
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

    /**
     * @notice Get count of created RWA Tokens.
     */
    function count() external view returns (uint256) {
        return tokens.length;
    }

    /**
     * @notice Get list of symbols of created RWA Tokens.
     */
    function list() external view returns (bytes32[] memory) {
        return tokens;
    }

    /**
     * @notice Helper function for converting string to bytes32
     * @param source String to convert.
     */
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
