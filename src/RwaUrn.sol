pragma solidity >=0.5.12;

contract VatLike {
    function frob(bytes32, address, address, address, int, int) public;
}

contract GemLike {
    function transfer(address, uint) public returns (bool);
    function transferFrom(address, address, uint) public returns (bool);
}

contract JoinLike {
    function ilk() public returns (bytes32);
    function gem() public returns (GemLike);
    function join(address, uint) public;
    function exit(address, uint) public;
}

contract RwaUrn {
    // --- auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "RwaUrn/not-authorized");
        _;
    }

    VatLike  public vat;
    JoinLike public gemJoin;
    JoinLike public daiJoin;
    address  public fbo;

    // --- init ---
    constructor(address vat_, address gemJoin_, address daiJoin_, address fbo_) public {
        vat = VatLike(vat_);
        gemJoin = JoinLike(gemJoin_);
        daiJoin = JoinLike(daiJoin_);
        fbo = fbo_;
        wards[msg.sender] = 1;
    }

    // --- cdp operation ---
    // n.b. DAI can only go to fbo
    function lock(uint256 wad) external auth {
        gemJoin.gem().transferFrom(msg.sender, address(this), wad);
        gemJoin.join(address(this), wad);
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), int(wad), 0);
    }
    function free(uint256 wad) external auth {
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), -int(wad), 0);
        gemJoin.exit(address(this), wad);
        gemJoin.gem().transfer(msg.sender, wad);
    }
    function draw(uint256 wad) external auth {
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), 0, int(wad));
        daiJoin.exit(fbo, wad);
    }
    function wipe(uint256 wad) external auth {
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), 0, -int(wad));
    }
}
