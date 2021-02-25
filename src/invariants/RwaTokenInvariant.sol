pragma solidity 0.5.12;

import "../RwaToken.sol";

/// @dev A contract that will receive RWA001, and allows for it to be retrieved.
contract MockHolder {
    // --- Math ---
    uint256 constant WAD = 10 ** 18;

    constructor (address rwa, address usr) public {
        RwaToken(rwa).approve(usr, 1 * WAD);
    }
}

/// @dev Invariant testing
contract RwaTokenInvariant {

    RwaToken internal rwa;
    address internal holder;

    /// @dev Instantiate the RwaToken contract, and a holder address that will return rwa when asked to.
    constructor () public {
        rwa = new RwaToken();
        holder = address(new MockHolder(address(rwa), address(this)));
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @dev Test that supply and balance hold on transfer.
    function transfer(uint wad) public {
        uint thisBalance = rwa.balanceOf(address(this));
        uint holderBalance = rwa.balanceOf(holder);
        rwa.transfer(holder, wad);
        assert(rwa.balanceOf(address(this)) == sub(thisBalance, wad));
        assert(rwa.balanceOf(holder) == add(holderBalance, wad));
        assert(address(rwa).balance == address(rwa).balance);
    }

    /// @dev Test that supply and balance hold on transferFrom.
    function transferFrom(uint wad) public {
        uint thisBalance = rwa.balanceOf(address(this));
        uint holderBalance = rwa.balanceOf(holder);
        rwa.transferFrom(holder, address(this), wad);
        assert(rwa.balanceOf(address(this)) == add(thisBalance, wad));
        assert(rwa.balanceOf(holder) == sub(holderBalance, wad));
        assert(address(rwa).balance == address(rwa).balance);
    }
}
