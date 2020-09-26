pragma solidity 0.5.12;

// AuthGemJoin
// For a token that needs restriction on the sources which are able to execute the join function (like SAI through Migration contract)

interface AuthGemLike {
    function decimals() external view returns (uint);
    function transfer(address,uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
}

contract AuthGemJoin is LibNote {
    VatLike     public vat;
    bytes32     public ilk;
    AuthGemLike public gem;
    uint        public dec;
    uint        public live;  // Access Flag

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) public note auth { wards[usr] = 1; }
    function deny(address usr) public note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1, "AuthGemJoin/non-authed"); _; }

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
        gem = AuthGemLike(gem_);
        dec = gem.decimals();
    }

    function cage() external note auth {
        live = 0;
    }

    function join(address usr, uint wad) public auth note {
        require(live == 1, "AuthGemJoin/not-live");
        require(int(wad) >= 0, "AuthGemJoin/overflow");
        vat.slip(ilk, usr, int(wad));
        require(gem.transferFrom(msg.sender, address(this), wad), "AuthGemJoin/failed-transfer");
    }

    function exit(address usr, uint wad) public note {
        require(wad <= 2 ** 255, "AuthGemJoin/overflow");
        vat.slip(ilk, msg.sender, -int(wad));
        require(gem.transfer(usr, wad), "AuthGemJoin/failed-transfer");
    }
}
