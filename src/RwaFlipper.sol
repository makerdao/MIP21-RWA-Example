pragma solidity >=0.5.12;

import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/CatAbstract.sol";

contract RwaFlipper {
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
        require(wards[msg.sender] == 1, "RwaFlipper/not-authorized");
        _;
    }

    VatAbstract public vat;
    CatAbstract public cat;
    bytes32 public ilk;
    uint256 public kicks = 0;

    // Events
    event Rely(address usr);
    event Deny(address usr);
    event File(bytes32 what, address data);
    event Kick(
        uint256 id,
        uint256 lot,
        uint256 bid,
        uint256 tab,
        address indexed usr,
        address indexed gal
    );

    // --- init ---
    constructor(address vat_, address cat_, bytes32 ilk_) public {
        vat = VatAbstract(vat_);
        cat = CatAbstract(cat_);
        ilk = ilk_;
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "cat") {
            cat = CatAbstract(data);
            emit File(what, data);
        }
        else revert("RwaFlipper/file-unrecognized-param");
    }

    function kick(
        address usr,
        address gal,
        uint256 tab,
        uint256 lot,
        uint256 bid
    ) public auth returns (uint256 id) {
        require(kicks < uint256(-1), "RwaFlipper/overflow");
        id = ++kicks;

        usr; gal; bid;
        vat.flux(ilk, msg.sender, address(this), lot);
        cat.claw(tab);
        emit Kick(id, lot, bid, tab, usr, gal);
    }
}
