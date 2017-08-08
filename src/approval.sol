import 'ds-token/token.sol';

contract Approval {
    mapping(bytes32=>address[]) slates;
    mapping(address=>bytes32) votes;
    mapping(address=>uint256) approvals;
    mapping(address=>uint256) deposits;
    DSToken public GOV; // voting token that gets locked up
    DSToken public IOU; // non-voting representation of a token, for e.g. secondary voting mechanisms
    address public gov; // governance rules

    uint256 public MAX_YAYS;

    // IOU constructed outside this contract reduces deployment costs significantly
    // lock/free/vote are quite sensitive to token invariants. Caution is advised.
    function Approval(uint MAX_YAYS_, DSToken GOV_, DSToken IOU_) {
        GOV = GOV_;
        IOU = IOU_;
        MAX_YAYS = MAX_YAYS_;
    }

    function lock(uint128 wad) {
        GOV.pull(msg.sender, wad);
        deposits[msg.sender] += wad;
        IOU.mint(wad);
        IOU.push(msg.sender, wad);
    }
    function free(uint128 wad) {
        IOU.pull(msg.sender, wad);
        IOU.burn(wad);
        deposits[msg.sender] -= wad;
        GOV.push(msg.sender, wad);
    }

    function etch(address[] yays) returns (bytes32 slate) {
        require( yays.length < MAX_YAYS );
        bytes32 hash = sha3(yays);
        slates[hash] = yays;
        return hash;
    }
    function addVote(bytes32 slate)
        internal
    {
        uint weight = deposits[msg.sender];
        var yays = slates[slate];
        for( uint i = 0; i < yays.length; i++ ) {
            approvals[yays[i]] += weight;
        }
    }
    function subVote(bytes32 slate)
        internal
    {
        uint weight = deposits[msg.sender];
        var yays = slates[slate];
        for( uint i = 0; i < yays.length; i++ ) {
            approvals[yays[i]] -= weight;
        }
    }
    function vote(bytes32 slate) {
        subVote(votes[msg.sender]);
        votes[msg.sender] = slate;
        addVote(votes[msg.sender]);
    }
    function vote(bytes32 slate, address lift_whom) {
        vote(slate);
        lift(lift_whom);
    }
    // like `drop`/`swap` except simply "elect this address if it is higher than current gov"
    function lift(address whom) {
        require(approvals[whom] > approvals[gov]);
        gov = whom;
    }
}
