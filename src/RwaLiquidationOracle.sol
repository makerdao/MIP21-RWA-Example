pragma solidity >=0.5.12;

contract PipLike {
    function poke(bytes32 wut) public;
}

contract RwaLiquidationOracle {
    // --- auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "RwaLiquidationOracle/not-authorized");
        _;
    }

    struct Ilk {
        bytes32 doc;
        PipLike pip;
        uint48  tau;
        uint48  toc;
    }
    mapping (bytes32 => Ilk) public ilks;

    constructor() public {
        wards[msg.sender] = 1;
    }

    function init(bytes32 ilk, bytes32 doc, address pip, uint48 tau) external auth {
        // pip, doc, and tau can be amended, but tau cannot decrease
        require(tau >= ilks[ilk].tau);
        ilks[ilk].pip = PipLike(pip);
        ilks[ilk].doc = doc;
        ilks[ilk].tau = tau;
    }

    // --- liquidation ---
    function tell(bytes32 ilk) external auth {
        require(ilks[ilk].pip != PipLike(address(0)));
        ilks[ilk].toc = uint48(now);
    }
    // --- remediation ---
    function cure(bytes32 ilk) external auth {
        ilks[ilk].toc = 0;
    }
    // --- write-off ---
    function cull(bytes32 ilk) external auth {
        require(ilks[ilk].tau != 0 && ilks[ilk].toc + ilks[ilk].tau >= now);
        ilks[ilk].pip.poke(bytes32(0));
    }

    // --- liquidation check ---
    function good(bytes32 ilk) external view returns (bool) {
        require(ilks[ilk].pip != PipLike(address(0)));
        return (ilks[ilk].toc == 0 || ilks[ilk].toc + ilks[ilk].tau < now);
    }
}
