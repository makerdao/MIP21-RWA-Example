pragma solidity >=0.5.12;

import "ds-test/test.sol";

import {RwaFlipper} from "./RwaFlipper.sol";
import {RwaLiquidationOracle} from "./RwaLiquidationOracle.sol";
import {RwaUrn} from "./RwaUrn.sol";

contract RwaExampleTest is DSTest {
    RwaFlipper flip;
    RwaLiquidationOracle oracle;
    RwaUrn urn;

    function setUp() public {
        oracle = new RwaLiquidationOracle();

        // flip = new RwaFlipper();
        // urn = new RwaUrn();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
