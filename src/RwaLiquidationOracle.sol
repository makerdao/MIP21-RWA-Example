pragma solidity >=0.5.12;

// gets us DSValueAbstract for pips
import "lib/dss-interfaces/src/dss/PipAbstract.sol";

contract RwaLiquidationOracle {
    // --- auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }
    modifier auth {
        require(wards[msg.sender] == 1, "RwaLiquidationOracle/not-authorized");
        _;
    }

    struct Ilk {
        bytes32         doc;
        DSValueAbstract pip;
        uint48          tau;
        uint48          toc;
    }
    mapping (bytes32 => Ilk) public ilks;

    // Events
    event Rely(address usr);
    event Deny(address usr);
    event Init(bytes32 ilk, bytes32 doc, address pip, uint48 tau);
    event Tell(bytes32 ilk);
    event Cure(bytes32 ilk);
    event Cull(bytes32 ilk);

    constructor() public {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function init(bytes32 ilk, bytes32 doc, address pip, uint48 tau) external auth {
        // pip, doc, and tau can be amended, but tau cannot decrease
        require(tau >= ilks[ilk].tau);
        ilks[ilk].pip = DSValueAbstract(pip);
        ilks[ilk].doc = doc;
        ilks[ilk].tau = tau;
        emit Init(ilk, doc, pip, tau);
    }

    // --- liquidation ---
    function tell(bytes32 ilk) external auth {
        require(ilks[ilk].pip != DSValueAbstract(address(0)));
        ilks[ilk].toc = uint48(now);
        emit Tell(ilk);
    }
    // --- remediation ---
    function cure(bytes32 ilk) external auth {
        ilks[ilk].toc = 0;
        emit Cure(ilk);
    }
    // --- write-off ---
    function cull(bytes32 ilk) external auth {
        require(ilks[ilk].tau != 0 && ilks[ilk].toc + ilks[ilk].tau >= now);
        ilks[ilk].pip.poke(bytes32(0));
        emit Cull(ilk);
    }

    // --- liquidation check ---
    function good(bytes32 ilk) external view returns (bool) {
        require(ilks[ilk].pip != DSValueAbstract(address(0)));
        return (ilks[ilk].toc == 0 || ilks[ilk].toc + ilks[ilk].tau < now);
    }
}
