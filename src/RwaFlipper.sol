pragma solidity >=0.5.12;

interface VatLike {
    function flux(bytes32,address,address,uint) external;
}


contract RwaFlipper {
    // --- auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "RwaFlipper/not-authorized");
        _;
    }

    VatLike public vat;
    bytes32 public ilk;
    uint256 public kicks = 0;


    // --- init ---
    constructor(address vat_, bytes32 ilk_) public {
        vat = VatLike(vat_);
        ilk = ilk_;
        wards[msg.sender] = 1;
    }

    function kick(address usr, address gal, uint tab, uint lot, uint bid) public auth returns (uint id) {
        require(kicks < uint(-1), "RwaFlipper/overflow");
        id = ++kicks;

        usr; gal; tab; bid;
        vat.flux(ilk, msg.sender, address(this), lot);
    }
}
