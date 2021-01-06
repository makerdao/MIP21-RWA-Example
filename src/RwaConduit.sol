pragma solidity 0.5.12;

import "lib/dss-interfaces/src/dapp/DSTokenAbstract.sol";

contract RwaConduit {
    DSTokenAbstract public gov;
    DSTokenAbstract public dai;
    address public to;

    event Push(address to, uint256 wad);

    constructor(address _gov, address _dai, address _to) public {
        gov = DSTokenAbstract(_gov);
        dai = DSTokenAbstract(_dai);
        to = _to;
    }

    function push() external {
        require(gov.balanceOf(msg.sender) > 0);
        emit Push(to, dai.balanceOf(address(this)));
        dai.transfer(to, dai.balanceOf(address(this)));
    }
}

contract RwaRoutingConduit {
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
        require(wards[msg.sender] == 1, "RwaConduit/not-authorized");
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
        require(can[msg.sender] == 1, "RwaConduit/not-operator");
        _;
    }

    DSTokenAbstract public gov;
    DSTokenAbstract public dai;

    address public to;
    mapping (address => uint256) public bud;

    // Events
    event Rely(address usr);
    event Deny(address usr);
    event Hope(address usr);
    event Nope(address usr);
    event Kiss(address who);
    event Diss(address who);
    event Pick(address who);
    event Push(address to, uint256 wad);

    constructor(address _gov, address _dai) public {
        wards[msg.sender] = 1;
        gov = DSTokenAbstract(_gov);
        dai = DSTokenAbstract(_dai);
        emit Rely(msg.sender);
    }

    // --- administration ---
    function kiss(address who) public auth {
        bud[who] = 1;
        emit Kiss(who);
    }
    function diss(address who) public auth {
        if (to == who) to = address(0);
        bud[who] = 0;
        emit Diss(who);
    }

    // --- routing ---
    function pick(address who) public operator {
        require(bud[who] == 1 || who == address(0), "RwaConduit/not-bud");
        to = who;
        emit Pick(who);
    }
    function push() external {
        require(to != address(0), "RwaConduit/to-not-set");
        require(gov.balanceOf(msg.sender) > 0, "RwaConduit/no-gov");
        emit Push(to, dai.balanceOf(address(this)));
        dai.transfer(to, dai.balanceOf(address(this)));
    }
}
