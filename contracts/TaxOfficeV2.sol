// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./owner/Operator.sol";
import "./interfaces/ITaxable.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IERC20.sol";

contract TaxOfficeV2 is Operator {
    using SafeMath for uint256;

    address public somb = address(0x55aC6a6C158633576743E0a08a00c358bbaCEeFf);
    address public wftm = address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    address public uniRouter = address(0xF491e7B69E4244ad4002BC14e878a34207E38c29);

    mapping(address => bool) public taxExclusionEnabled;

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
        return _excludeAddressFromTax(_address);
    }

    function _excludeAddressFromTax(address _address) private returns (bool) {
        if (!ITaxable(somb).isAddressExcluded(_address)) {
            return ITaxable(somb).excludeAddress(_address);
        }
    }

    function includeAddressInTax(address _address) external onlyOperator returns (bool) {
        return _includeAddressInTax(_address);
    }

    function _includeAddressInTax(address _address) private returns (bool) {
        if (ITaxable(somb).isAddressExcluded(_address)) {
            return ITaxable(somb).includeAddress(_address);
        }
    }

    function taxRate() external view returns (uint256) {
        return ITaxable(somb).taxRate();
    }

    function addLiquidityTaxFree(
        address token,
        uint256 amtSomb,
        uint256 amtToken,
        uint256 amtSombMin,
        uint256 amtTokenMin
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(amtSomb != 0 && amtToken != 0, "amounts can't be 0");
        _excludeAddressFromTax(msg.sender);

        IERC20(somb).transferFrom(msg.sender, address(this), amtSomb);
        IERC20(token).transferFrom(msg.sender, address(this), amtToken);
        _approveTokenIfNeeded(somb, uniRouter);
        _approveTokenIfNeeded(token, uniRouter);

        _includeAddressInTax(msg.sender);

        uint256 resultAmtSomb;
        uint256 resultAmtToken;
        uint256 liquidity;
        (resultAmtSomb, resultAmtToken, liquidity) = IUniswapV2Router(uniRouter).addLiquidity(
            somb,
            token,
            amtSomb,
            amtToken,
            amtSombMin,
            amtTokenMin,
            msg.sender,
            block.timestamp
        );

        if(amtSomb.sub(resultAmtSomb) > 0) {
            IERC20(somb).transfer(msg.sender, amtSomb.sub(resultAmtSomb));
        }
        if(amtToken.sub(resultAmtToken) > 0) {
            IERC20(token).transfer(msg.sender, amtToken.sub(resultAmtToken));
        }
        return (resultAmtSomb, resultAmtToken, liquidity);
    }

    function addLiquidityETHTaxFree(
        uint256 amtSomb,
        uint256 amtSombMin,
        uint256 amtFtmMin
    )
        external
        payable
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(amtSomb != 0 && msg.value != 0, "amounts can't be 0");
        _excludeAddressFromTax(msg.sender);

        IERC20(somb).transferFrom(msg.sender, address(this), amtSomb);
        _approveTokenIfNeeded(somb, uniRouter);

        _includeAddressInTax(msg.sender);

        uint256 resultAmtSomb;
        uint256 resultAmtFtm;
        uint256 liquidity;
        (resultAmtSomb, resultAmtFtm, liquidity) = IUniswapV2Router(uniRouter).addLiquidityETH{value: msg.value}(
            somb,
            amtSomb,
            amtSombMin,
            amtFtmMin,
            msg.sender,
            block.timestamp
        );

        if(amtSomb.sub(resultAmtSomb) > 0) {
            IERC20(somb).transfer(msg.sender, amtSomb.sub(resultAmtSomb));
        }
        return (resultAmtSomb, resultAmtFtm, liquidity);
    }

    function setTaxableSombOracle(address _sombOracle) external onlyOperator {
        ITaxable(somb).setSombOracle(_sombOracle);
    }

    function transferTaxOffice(address _newTaxOffice) external onlyOperator {
        ITaxable(somb).setTaxOffice(_newTaxOffice);
    }

    function taxFreeTransferFrom(
        address _sender,
        address _recipient,
        uint256 _amt
    ) external {
        require(taxExclusionEnabled[msg.sender], "Address not approved for tax free transfers");
        _excludeAddressFromTax(_sender);
        IERC20(somb).transferFrom(_sender, _recipient, _amt);
        _includeAddressInTax(_sender);
    }

    function setTaxExclusionForAddress(address _address, bool _excluded) external onlyOperator {
        taxExclusionEnabled[_address] = _excluded;
    }

    function _approveTokenIfNeeded(address _token, address _router) private {
        if (IERC20(_token).allowance(address(this), _router) == 0) {
            IERC20(_token).approve(_router, type(uint256).max);
        }
    }
}
