// TODO: figure out how to use this.

// SPDX-License-Identifier: AGPL-3.0-or-later
//
// RwaTokenInvariant.sol -- RWA Token Invariant testing
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

pragma solidity 0.6.12;

import "../RwaToken.sol";

/// @dev A contract that will receive RWA001, and allows for it to be retrieved.
contract MockHolder {
    // --- Math ---
    uint256 internal constant WAD = 10**18;

    constructor(address rwa, address usr) public {
        RwaToken(rwa).approve(usr, 1 * WAD);
    }
}

/// @dev Invariant testing
contract RwaTokenInvariant {
    RwaToken internal rwa;
    address internal holder;

    string internal name = "RWA-001";
    string internal symbol = "RWA001";

    /// @dev Instantiate the RwaToken contract, and a holder address that will return rwa when asked to.
    constructor() public {
        rwa = new RwaToken(name, symbol);
        holder = address(new MockHolder(address(rwa), address(this)));
    }

    // --- Math ---
    uint256 internal constant WAD = 10**18;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @dev Test that supply and balance hold on transfer.
    function transfer(uint256 wad) public {
        uint256 thisBalance = rwa.balanceOf(address(this));
        uint256 holderBalance = rwa.balanceOf(holder);
        rwa.transfer(holder, wad);
        assert(rwa.balanceOf(address(this)) == sub(thisBalance, wad));
        assert(rwa.balanceOf(holder) == add(holderBalance, wad));
        assert(address(rwa).balance == address(rwa).balance);
    }

    /// @dev Test that supply and balance hold on transferFrom.
    function transferFrom(uint256 wad) public {
        uint256 thisBalance = rwa.balanceOf(address(this));
        uint256 holderBalance = rwa.balanceOf(holder);
        rwa.transferFrom(holder, address(this), wad);
        assert(rwa.balanceOf(address(this)) == add(thisBalance, wad));
        assert(rwa.balanceOf(holder) == sub(holderBalance, wad));
        assert(address(rwa).balance == address(rwa).balance);
    }
}
