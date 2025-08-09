# Decentralized Roommate Matching Smart Contract

A comprehensive smart contract built on the Stacks blockchain for decentralized roommate matching, enabling secure and transparent connections between potential roommates.

##  Overview

This smart contract provides a decentralized platform where users can:
- Create detailed profiles with preferences and requirements
- Send match requests to potential roommates
- Accept or reject incoming match requests
- Rate and review roommates after successful matches
- Manage their profile visibility and activity status

##  Features

### Core Functionality
- **User Registration**: Complete profile creation with personal details, preferences, and budget constraints
- **Profile Management**: Update profile information, deactivate accounts
- **Match Requests**: Send targeted match requests with personalized messages
- **Response System**: Accept or reject incoming match requests
- **Rating System**: Rate and review users based on roommate experiences
- **Fee System**: Platform fee collection for match requests

### Security Features
- **Principal-based Authentication**: Secure user identification using Stacks principals
- **Input Validation**: Comprehensive validation for age, budget, and other parameters
- **Access Control**: Users can only modify their own profiles and respond to their own requests
- **Expiration System**: Match requests automatically expire after 7 days

## Getting Started

### Prerequisites
- Stacks blockchain development environment
- Clarity CLI or Clarinet for testing and deployment
- STX tokens for transaction fees and platform fees

### Deployment
1. Clone the repository
2. Install Clarinet: `npm install -g @hirosystems/clarinet`
3. Test the contract: `clarinet test`
4. Deploy to testnet: `clarinet deploy --testnet`

### Usage Examples

#### Register a New User
```clarity
(contract-call? .roommate-matching register-user
  "John Doe"
  u25
  "San Francisco, CA"
  u500000000  ;; 500 STX minimum budget
  u1000000000 ;; 1000 STX maximum budget
  (list "non-smoker" "pet-friendly" "quiet")
  "Software engineer looking for a clean, quiet roommate"
)
```

#### Send a Match Request
```clarity
(contract-call? .roommate-matching send-match-request
  u2  ;; Target user ID
  "Hi! I think we'd be great roommates based on our similar preferences."
)
```

#### Respond to a Match Request
```clarity
(contract-call? .roommate-matching respond-to-match-request
  u1  ;; Match request ID
  true ;; Accept the request
)
```

#### Rate a User
```clarity
(contract-call? .roommate-matching rate-user
  u2  ;; User to rate
  u5  ;; Rating (1-5)
  "Great roommate, very clean and respectful!"
)
```

##  Contract Structure

### Data Maps
- **users**: Stores complete user profiles with preferences and ratings
- **user-principals**: Maps Stacks principals to user IDs
- **match-requests**: Tracks all match requests and their statuses
- **active-matches**: Records successful matches between users
- **user-ratings**: Stores ratings and reviews between users

### Key Constants
- **platform-fee**: 1 STX fee for sending match requests
- **min-age/max-age**: Age validation boundaries (18-100)
- **max-preferences**: Maximum of 10 preference items per user

##  Functions Reference

### Public Functions
| Function | Description | Fee Required |
|----------|-------------|--------------|
| `register-user` | Create a new user profile | No |
| `update-profile` | Modify existing profile | No |
| `send-match-request` | Send match request to another user | 1 STX |
| `respond-to-match-request` | Accept/reject match request | No |
| `rate-user` | Rate and review a user | No |
| `deactivate-profile` | Disable user profile | No |

### Read-Only Functions
| Function | Description |
|----------|-------------|
| `get-user-profile` | Retrieve user profile by ID |
| `get-user-by-principal` | Get profile by Stacks principal |
| `get-match-request` | View match request details |
| `get-active-match` | View active match information |
| `get-platform-stats` | Platform usage statistics |

##  Security Considerations

- **No Sensitive Data**: Contract doesn't store passwords or private information
- **Principal Verification**: All actions verified against user's Stacks principal
- **Input Validation**: Age, budget, and rating constraints enforced
- **Expiration Logic**: Match requests expire to prevent spam
- **Fee Protection**: Platform fees prevent spam match requests

##  Economics

- **Match Request Fee**: 1 STX per match request
- **Revenue Model**: Platform collects fees for sustainability
- **User Ratings**: Free rating system encourages good behavior

##  Testing

The contract includes comprehensive error handling:
- `err-owner-only` (u100): Only contract owner can perform action
- `err-not-found` (u101): Requested resource doesn't exist
- `err-already-exists` (u102): User already registered
- `err-unauthorized` (u103): User not authorized for action
- `err-invalid-input` (u104): Invalid input parameters
- `err-insufficient-payment` (u105): Insufficient fee payment
- `err-already-matched` (u106): Users already matched
- `err-match-not-found` (u107): Match request not found
- `err-invalid-rating` (u108): Rating outside valid range (1-5)

##  Future Enhancements

- **Advanced Matching Algorithm**: AI-based compatibility scoring
- **Escrow System**: Deposit handling for lease agreements
- **Messaging System**: Direct communication between matched users
- **Location Services**: GPS-based proximity matching
- **Multi-language Support**: Internationalization features

##  Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

##  License

This project is licensed under the MIT License - see the LICENSE file for details.

##  Support

For questions or support, please open an issue in the GitHub repository or contact the development team.
