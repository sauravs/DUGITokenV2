// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DUGI Token V2
/// @notice Implementation of DUGI Token with burning mechanism and SafeERC20 features
/// @dev Extends ERC20Permit for gasless transactions, ERC20Pausable for pausability, and implements SafeERC20
contract DUGITokenV2 is ERC20Permit, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Maximum token supply - 21 trillion tokens
    uint256 public constant MAX_SUPPLY = 21_000_000_000_000 * 10 ** 18;


    /// @notice 5% of maximum supply reserved for donation
    uint256 public donationReserve = (MAX_SUPPLY * 5) / 100;

    /// @notice 10% of maximum supply reserved for token burning
    uint256 public burnReserve = (MAX_SUPPLY * 10) / 100;


    /// @notice Time interval between burn operations (30 days)
    uint256 public constant BURN_INTERVAL = 30 days;

    /// @notice Address receiving initial 5% donation allocation
    address public donationWallet;

    /// @notice Address authorized to execute token burns - can be updated by owner
    address public tokenBurnAdmin;

    /// @notice Timestamp of the last burn operation
    uint256 public lastBurnTimestamp;


    /// @notice Indicates if burning cycle has started
    bool public burnStarted;

    /// @notice Indicates if burning cycle has ended
    bool public burnEnded;

    /// @notice Total number of burn rounds (35 years * 12 months + 1 month for residual)
    uint256 public constant TOTAL_BURN_SLOTS = 421;

    /// @notice Counter tracking completed burn rounds
    uint32 public burnCounter;

    /// @notice Emitted when tokens are burned from reserve
    /// @param amount The amount of tokens burned
    /// @param timestamp The time when burning occurred
    /// @param burnCount The current burn round number
    event TokensBurned(uint256 indexed amount, uint256 indexed timestamp, uint256 indexed burnCount);

    /// @notice Emitted when tokenBurnAdmin is changed
    /// @param oldAdmin Previous burn admin address
    /// @param newAdmin New burn admin address
    event TokenBurnAdminChanged(address indexed oldAdmin, address indexed newAdmin);

    /// @dev Custom errors
    error ZeroAddress();
    error NotBurnAdmin();
    error BurnIntervalNotReached();
    error BurnReserveEmpty();
    error BurningHasEnded();

    /// @notice Initializes the token with initial supply distribution
    /// @dev Sets up donation wallet and burn admin, distributes initial supply to predefined owner
    /// @param _donationWallet Address to receive 5% of initial supply
    /// @param _tokenBurnAdmin Initial burn admin address
    constructor(address _donationWallet, address _tokenBurnAdmin)
        ERC20("DUGI Token", "DUGI")
        ERC20Permit("DUGI Token")
        Ownable(0x1e364a3634289Bc315a6DFF4e5fD018B5C6B3ef6)
    {
        if (_donationWallet == address(0)) revert ZeroAddress();
        if (_tokenBurnAdmin == address(0)) revert ZeroAddress();

        donationWallet = _donationWallet;
        tokenBurnAdmin = _tokenBurnAdmin;
        lastBurnTimestamp = block.timestamp;

       

        uint256 ownerAmount = MAX_SUPPLY - donationReserve - burnReserve;  // 85% of max supply

        _mint(address(this), burnReserve);
        _mint(donationWallet, donationReserve);
        _mint(0x1e364a3634289Bc315a6DFF4e5fD018B5C6B3ef6, ownerAmount);

    }

    /// @notice Allows owner to change the token burn admin
    /// @param _tokenBurnAdmin New burn admin address
    function setTokenBurnAdmin(address _tokenBurnAdmin) external onlyOwner {
        if (_tokenBurnAdmin == address(0)) revert ZeroAddress();
        address oldAdmin = tokenBurnAdmin;
        tokenBurnAdmin = _tokenBurnAdmin;
        emit TokenBurnAdminChanged(oldAdmin, _tokenBurnAdmin);
    }

    /// @notice Burns tokens from the burn reserve
    /// @dev Burns 0.0714% of max supply if conditions are met
   function burnFromReserve() external {
    if (msg.sender != tokenBurnAdmin) revert NotBurnAdmin();
    if (block.timestamp < lastBurnTimestamp + BURN_INTERVAL) revert BurnIntervalNotReached();
    if (burnReserve <= 0) revert BurnReserveEmpty();
    if (burnEnded) revert BurningHasEnded();

    if (!burnStarted) {
        burnStarted = true;
    }

    uint256 burnAmount = (MAX_SUPPLY * 714) / 1_000_000; // 0.0714%

    // Ensure burnAmount does not exceed burnReserve
    if (burnAmount > burnReserve) {
        burnAmount = burnReserve;
    }

    burnReserve -= burnAmount;
    _burn(address(this), burnAmount);

    burnCounter++;

    if (burnCounter >= TOTAL_BURN_SLOTS || burnReserve == 0) {
        burnEnded = true;
    }

    lastBurnTimestamp = block.timestamp;
    emit TokensBurned(burnAmount, block.timestamp, burnCounter);
}

  


}
