// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./owner/Operator.sol";
import "./interfaces/ITaxable.sol";

contract TaxOffice is Operator {
    address public somb;

    constructor(address _somb) public {
        require(_somb != address(0), "somb address cannot be 0");
        somb = _somb;
    }

    function setTaxTiersTwap(uint8 _index, uint256 _value) public onlyOperator returns (bool) {
        return ITaxable(somb).setTaxTiersTwap(_index, _value);
    }

    function setTaxTiersRate(uint8 _index, uint256 _value) public onlyOperator returns (bool) {
        return ITaxable(somb).setTaxTiersRate(_index, _value);
    }

    function enableAutoCalculateTax() public onlyOperator {
        ITaxable(somb).enableAutoCalculateTax();
    }

    function disableAutoCalculateTax() public onlyOperator {
        ITaxable(somb).disableAutoCalculateTax();
    }

    function setTaxRate(uint256 _taxRate) public onlyOperator {
        ITaxable(somb).setTaxRate(_taxRate);
    }

    function setBurnThreshold(uint256 _burnThreshold) public onlyOperator {
        ITaxable(somb).setBurnThreshold(_burnThreshold);
    }

    function setTaxCollectorAddress(address _taxCollectorAddress) public onlyOperator {
        ITaxable(somb).setTaxCollectorAddress(_taxCollectorAddress);
    }

    function excludeAddressFromTax(address _address) external onlyOperator returns (bool) {
        return ITaxable(somb).excludeAddress(_address);
    }

    function includeAddressInTax(address _address) external onlyOperator returns (bool) {
        return ITaxable(somb).includeAddress(_address);
    }

    function setTaxableSombOracle(address _sombOracle) external onlyOperator {
        ITaxable(somb).setSombOracle(_sombOracle);
    }

    function transferTaxOffice(address _newTaxOffice) external onlyOperator {
        ITaxable(somb).setTaxOffice(_newTaxOffice);
    }
}
