pragma solidity 0.5.12;

contract SpellAction {
    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.0/contracts.json
    address constant MCD_VAT                = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_CAT                = 0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea;
    address constant MCD_JUG                = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_SPOT               = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant MCD_END                = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant FLIPPER_MOM            = 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472;
    address constant OSM_MOM                = 0x76416A4d5190d071bfed309861527431304aA14f;
    address constant ILK_REGISTRY           = 0x8b4ce5DCbb01e0e1f0521cd8dCfb31B308E52c24;

    address constant SIXSA_GEM              = ???;
    address constant MCD_JOIN_SIXSA         = ???;
    address constant MCD_FLIP_SIXSA         = ???;
    address constant PIP_SIXSA              = ???;

    function execute() external {

        ////////////////////////////////////////////////////////////////////////////////
        // SIXS-A collateral deploy

        // Set ilk bytes32 variable
        bytes32 ilkSIXSA = "SIXS-A";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_SIXSA).vat() == MCD_VAT,                  "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_SIXSA).ilk() == ilkSIXSA,                 "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_SIXSA).gem() == SIXSA_GEM,   	                "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_SIXSA).dec() == ERC20(SIXSA_GEM).decimals(),   "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_SIXSA).vat()    == MCD_VAT,                  "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_SIXSA).ilk()    == ilkSIXSA,                 "flip-ilk-not-match");

        // Set price feed for SIXSA
        SpotAbstract(MCD_SPOT).file(ilkSIXSA, "pip", PIP_SIXSA);

        // Set the SIXS-A flipper in the cat
        CatAbstract(MCD_CAT).file(ilkSIXSA, "flip", MCD_FLIP_SIXSA);

        // Init SIXS-A in Vat
        VatAbstract(MCD_VAT).init(ilkSIXSA);
        // Init SIXS-A in Jug
        JugAbstract(MCD_JUG).init(ilkSIXSA);

        // Allow SIXS-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_SIXSA);

        // Allow SIXS-A Flipper on the Cat
        CatAbstract(MCD_CAT).rely(MCD_FLIP_SIXSA);

        // Allow cat to kick auctions in SIXS-A Flipper
        FlipAbstract(MCD_FLIP_SIXSA).rely(MCD_CAT);

        // Allow End to yank auctions in SIXS-A Flipper
        // TODO
        FlipAbstract(MCD_FLIP_SIXSA).rely(MCD_END);

        // Allow FlipperMom to access the SIXS-A Flipper
        // TODO
        FlipAbstract(MCD_FLIP_SIXSA).rely(FLIPPER_MOM);

        // Update OSM
        // TODO
        OsmAbstract(PIP_SIXSA).rely(OSM_MOM);
        MedianAbstract(OsmAbstract(PIP_SIXSA).src()).kiss(PIP_SIXSA);
        OsmAbstract(PIP_SIXSA).kiss(MCD_SPOT);
        OsmAbstract(PIP_SIXSA).kiss(MCD_END);
        OsmMomAbstract(OSM_MOM).setOsm(ilkSIXSA, PIP_SIXSA);

        // since we're adding 2 collateral types in this spell, global line is at beginning
        // TODO Line
        VatAbstract(MCD_VAT).file( ilkSIXSA, "line", 10 * MILLION * RAD   ); // 10m debt ceiling
        VatAbstract(MCD_VAT).file( ilkSIXSA, "dust", 100 * RAD            ); // 100 Dai dust
        CatAbstract(MCD_CAT).file( ilkSIXSA, "dunk", 50 * THOUSAND * RAD  ); // 50,000 dunk
        CatAbstract(MCD_CAT).file( ilkSIXSA, "chop", 113 * WAD / 100      ); // 13% liq. penalty
        JugAbstract(MCD_JUG).file( ilkSIXSA, "duty", SIX_PCT_RATE         ); // 6% stability fee

        // TODO
        FlipAbstract(MCD_FLIP_SIXSA).file(  "beg" , 103 * WAD / 100      ); // 3% bid increase
        FlipAbstract(MCD_FLIP_SIXSA).file(  "ttl" , 6 hours              ); // 6 hours ttl
        FlipAbstract(MCD_FLIP_SIXSA).file(  "tau" , 6 hours              ); // 6 hours tau

        // TODO
        SpotAbstract(MCD_SPOT).file(ilkSIXSA, "mat",  150 * RAY / 100     ); // 150% coll. ratio
        SpotAbstract(MCD_SPOT).poke(ilkSIXSA);

        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_SIXSA);
}

contract DssSpell {
    DSPauseAbstract  public pause;
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    uint256          public expiration;
    bool             public done;

    address constant MCD_PAUSE = 0xbE286431454714F511008713973d3B053A2d38f3;

    // You could remove this or do (now + X days) for MIP21
    uint256 constant T2021_02_01_1200UTC = 1612180800;

    // Provides a descriptive tag for bot consumption
    string constant public description = "Empty Executive Spell";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        pause = DSPauseAbstract(MCD_PAUSE);
        expiration = T2021_02_01_1200UTC;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + pause.delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
