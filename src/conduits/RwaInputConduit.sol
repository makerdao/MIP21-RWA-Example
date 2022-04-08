// SPDX-License-Identifier: AGPL-3.0-or-later
//
// RwaInputConduit.sol -- In and out conduits for Dai
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

import "dss-interfaces/dapp/DSTokenAbstract.sol";

contract RwaInputConduit {
    DSTokenAbstract public gov;
    DSTokenAbstract public dai;
    address public to;

    event Push(address indexed to, uint256 wad);

    constructor(
        address _gov,
        address _dai,
        address _to
    ) public {
        gov = DSTokenAbstract(_gov);
        dai = DSTokenAbstract(_dai);
        to = _to;
    }

    function push() external {
        require(gov.balanceOf(msg.sender) > 0, "RwaConduit/no-gov");
        uint256 balance = dai.balanceOf(address(this));
        emit Push(to, balance);
        dai.transfer(to, balance);
    }
}
