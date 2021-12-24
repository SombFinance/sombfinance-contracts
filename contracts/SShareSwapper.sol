pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./owner/Operator.sol";

contract SShareSwapper is Operator {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public somb;
    IERC20 public sbond;
    IERC20 public sshare;

    address public sombSpookyLpPair;
    address public sshareSpookyLpPair;

    address public wftmAddress;

    address public daoAddress;

    event SBondSwapPerformed(address indexed sender, uint256 sbondAmount, uint256 sshareAmount);


    constructor(
            address _somb,
            address _sbond,
            address _sshare,
            address _wftmAddress,
            address _sombSpookyLpPair,
            address _sshareSpookyLpPair,
            address _daoAddress
    ) public {
        somb = IERC20(_somb);
        sbond = IERC20(_sbond);
        sshare = IERC20(_sshare);
        wftmAddress = _wftmAddress; 
        sombSpookyLpPair = _sombSpookyLpPair;
        sshareSpookyLpPair = _sshareSpookyLpPair;
        daoAddress = _daoAddress;
    }


    modifier isSwappable() {
        //TODO: What is a good number here?
        require(somb.totalSupply() >= 60 ether, "ChipSwapMechanismV2.isSwappable(): Insufficient supply.");
        _;
    }

    function estimateAmountOfSShare(uint256 _sbondAmount) external view returns (uint256) {
        uint256 sshareAmountPerSomb = getSShareAmountPerSomb();
        return _sbondAmount.mul(sshareAmountPerSomb).div(1e18);
    }

    function swapSBondToSShare(uint256 _sbondAmount) external {
        require(getSBondBalance(msg.sender) >= _sbondAmount, "Not enough SBond in wallet");

        uint256 sshareAmountPerSomb = getSShareAmountPerSomb();
        uint256 sshareAmount = _sbondAmount.mul(sshareAmountPerSomb).div(1e18);
        require(getSShareBalance() >= sshareAmount, "Not enough SShare.");

        sbond.safeTransferFrom(msg.sender, daoAddress, _sbondAmount);
        sshare.safeTransfer(msg.sender, sshareAmount);

        emit SBondSwapPerformed(msg.sender, _sbondAmount, sshareAmount);
    }

    function withdrawSShare(uint256 _amount) external onlyOperator {
        require(getSShareBalance() >= _amount, "ChipSwapMechanism.withdrawFish(): Insufficient FISH balance.");
        sshare.safeTransfer(msg.sender, _amount);
    }

    function getSShareBalance() public view returns (uint256) {
        return sshare.balanceOf(address(this));
    }

    function getSBondBalance(address _user) public view returns (uint256) {
        return sbond.balanceOf(_user);
    }

    function getSombPrice() public view returns (uint256) {
        return IERC20(wftmAddress).balanceOf(sombSpookyLpPair)
            .mul(1e18)
	    .div(somb.balanceOf(sombSpookyLpPair));
    }

    function getSSharePrice() public view returns (uint256) {
        return IERC20(wftmAddress).balanceOf(sshareSpookyLpPair)
            .mul(1e18)
            .div(sshare.balanceOf(sshareSpookyLpPair));
    }

    function getSShareAmountPerSomb() public view returns (uint256) {
        uint256 sombPrice = IERC20(wftmAddress).balanceOf(sombSpookyLpPair)
            .mul(1e18)
	    .div(somb.balanceOf(sombSpookyLpPair));

        uint256 ssharePrice =
            IERC20(wftmAddress).balanceOf(sshareSpookyLpPair)
	    .mul(1e18)
            .div(sshare.balanceOf(sshareSpookyLpPair));
            

        return sombPrice.mul(1e18).div(ssharePrice);
    }

}