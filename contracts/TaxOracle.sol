// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SombTaxOracle is Ownable {
    using SafeMath for uint256;

    IERC20 public somb;
    IERC20 public wftm;
    address public pair;

    constructor(
        address _somb,
        address _wftm,
        address _pair
    ) public {
        require(_somb != address(0), "somb address cannot be 0");
        require(_wftm != address(0), "wftm address cannot be 0");
        require(_pair != address(0), "pair address cannot be 0");
        somb = IERC20(_somb);
        wftm = IERC20(_wftm);
        pair = _pair;
    }

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut) {
        require(_token == address(somb), "token needs to be somb");
        uint256 sombBalance = somb.balanceOf(pair);
        uint256 wftmBalance = wftm.balanceOf(pair);
        return uint144(sombBalance.div(wftmBalance));
    }

    function setSomb(address _somb) external onlyOwner {
        require(_somb != address(0), "somb address cannot be 0");
        somb = IERC20(_somb);
    }

    function setWftm(address _wftm) external onlyOwner {
        require(_wftm != address(0), "wftm address cannot be 0");
        wftm = IERC20(_wftm);
    }

    function setPair(address _pair) external onlyOwner {
        require(_pair != address(0), "pair address cannot be 0");
        pair = _pair;
    }



}
