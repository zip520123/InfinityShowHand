pragma solidity >=0.5.0 <0.6.0;

contract InfinityGame {

  uint8 constant public numberOfPlayer = 5;
  uint8 constant public numberOfGames = 5;
  uint256 public timeOfAGame = 3 minutes;

  enum Suit { Diamond, Club, Heart, Spade }
  enum Value { Eight, Nine, Ten, Jack, Queen, King, Ace}
  enum HandEnum { Zilch, OnePair, TwoPair, ThreeOfAKind, Straight, Flush, FullHouse, FourOfAKind, StraightFlush }
  enum CampareResult { Bigger, Lower, Same }

  struct Card {
    Suit suit;
    Value value;
  }

  struct Deck {
    Card[28] cards;
  }

  struct Game {
    uint id;
    Player[numberOfPlayer] players;
    uint endTime;
    Deck deck;
  }

  struct Player {
    uint id;
    address[] bettors;
    Card[] cards;
  }

  struct HandRank {
    HandEnum handEnum;
    Card[] cards;
  }

  Game[] public games;
  mapping(uint => Game) IDToGames;
  bool canBet;

  uint public feeRate = 0.1;
  uint public playerLimit = 0.1 ether;

  function start() public {
    for(uint i=0;i<numberOfGames;i++){
      Game memory game = createGame();
      games.push(game);
    }
    canBet = true;
  }


  function bet(Player memory player) public payable {
    require (msg.value == playerLimit);
    require (canBet == true);
    player.bettor.push(msg.sender);
  }

  function createGame() private returns (Game memory) {
    Player[numberOfPlayer] memory players;
    
    Deck deck = newDeck();

    for(uint i=0;i<numbserOfPlayer;i++){

      Card[] cards = [];
      for(uint j=0;j<4;j++){
        cards.push(deck.shift());
      }
      player = createPlayer(cards);
      players.push(player);
    }
    uint id = random();
    while(IDToGames[id] != address(0x0)){
      id = random();
    }
    return  Game(id, players, deck, block.timestamp.add(timeOfAGame));
  }

  function createPlayer(Card[] memory cards) private returns(Player memory){
    uint id = random();
    while(IDToPlayer[id] != address(0x0)) {
      id = random();
    }
    return Player(id, [], cards);
  }

  function newDeck() private returns (Deck memory) {
    //create deck
    Card[] cards = [];
    for(i=0;i<4;i++) {
      for(j=0;j<8;j++){
        Card card = Card(Suit(i), Value(j));
        cards.push(card);
      }
    }
    //cards shuffle
    for(i=0;i<cards.length;i++){
      uint randNum = random().mod(28);
      Card temp = card[i];
      card[i] = card[randNum];
      card[randNum] = card[i];
    }

    return Deck(cards);
  }

  function settlement() public {
    canBet = false;
    for (uint i=0 ; i<games.length;i++) {
      Game game = games[i];
      sendLatestCard(game);
      Player[] winners = pickWinners(game);
      uint stack = stackInGame(game);
      sendEth(bettors, stack);

    }
    delete games;
  }

  function sendLatestCard(Game memory game) private {
    require(block.timestamp >= game.endTime);
    require(canBet == false);
    for (uint i=0;i<game.players.length;i++) {
      Player player = game.players[i];
      player.cards.push(game.deck.shift);
    }
  }

  function stackInGame(Game memory game) private returns (uint) {
    uint stack = 0;
    for (uint i=0;i<game.players.length;i++) {
      Player player = game.players[i];
      for(uint j=0;j<player.bettors.length;j++){

        stack += playerLimit;
      }
    }
    return stack;
  }

  function pickWinners(Game memory game) private returns (Player[] memory) {
    //sometime draw we need picker winner list
    Player winners = [game.players[0]];
    HandRand hand1 = evalutate(winner);
    for(i=1;i<numberOfPlayer;i++){
      Player challenger = game.players[i];
      HandRand hand2 = evaluate(challenger);
      result = hand1BeatHand2(hand1,hand2);
      if (result == Bigger) {
        winners = [challenger];
        HandRand = hand2;
      }else if (result == some){
        winners.push(hand2);
      }
    }
    return winners;
  }

  function evaluate(Player memory player) private returns (HandRank memory) {
    //sort player cards first
    for(uint i=0;i<player.cards.length;i++){
      for(uint j=i+1;j<player.cards.length;j++){
        if (player.cards[i].value > player.cards[j].value){
          Card temp = player.cards[i];
          player.cards[i] = player.cards[j];
          player.cards[j] = temp;
        }
      }
    }

    uint8 suitCount = [0,0,0,0];
    uint8 cardNumberCount = [0,0,0,0,0,0,0];
    uint8 pairs = 0;
    HandEnum handEnum = HandEnum.Zilch;

    for(uint i =0;i<player.cards.length;i++){
      Card card = player.cards[i];
      suitCount[card.suit] = suitCount[card.suit].add(1);
      cardNumberCount[card.value] = cardNumberCount[card.value].add(1);

      if (cardNumberCount[card.value] == 4){
        handEnum = HandEnum.FourOfAKind;
        return HandRank(handEnum, player.cards);
      } else if (cardNumberCount[card.value] == 3){
        handEnum = HandEnum.ThreeOfAKind;
      } else if (cardNumberCount[card.value] == 2){
        pairs++;
      }
    }

    if(suitCount[player.cards[0]] == 5){
      if(player.cards[4].value - player.cards[0].value == 4){
        handEnum = HandEnum.StraightFlush;
        return HandRank(handEnum, player.cards);
      }else{
        handEnum = HandEnum.Flush;
        return HandRand(handEnum, player.cards);
      }
    }

    if (handEnum == ThreeOfAKind) {
      if (pairs == 2){
        handEnum = HandEnum.FullHouse;
        return HandRand(handEnum, player.cards);
      }else{
        return HandRand(handEnum, player.cards);
      }
    }
    
    if (pairs == 1) {
      handEnum = HandEnum.OnePair;
    } else if (pairs == 2){
      handEnum = HandEnum.TwoPair;
    } else if (pairs == 0){
      handEnum = HandEnum.Straight;
    }

    return HandRand(handEnum, player.cards);
  }

  function hand1BeatHand2(HandRank memory hand1, HandRank memory hand2) public returns (CampareResult) {
    if (hand1.handEnum > hand2.handEnum){
      return CampareResult.Bigger;
    }else if (hand2.handEnum > hand2.handEnum){
      return CampareResult.Lower;
    }else {
      if (hand1.handEnum == Zilch) {
        //find max card num
        //if hand1.max Card num == hand2.max card num
        //campare second high card number
        for(i=hand1.cards.length - 1;i>=0;i--){
          if (hand1.cards[i] > hand2.cards[i]) {
            return CampareResult.Bigger;
          } else if (hand1.cards[i] < hand2.cards[i]){
            return CampareResult;
          }
        }
      } else if (hand1.handEnum == OnePair){
        //A hand with two cards of equal rank and three cards which are different from these and from each other. When comparing two such hands, the hand with the higher pair is better - so for example 6-6-4-3-2 beats 5-5-A-K-Q. If the pairs are equal, compare the highest ranking odd cards from each hand; if these are equal compare the second highest odd card, and if these are equal too compare the lowest odd cards. So J-J-A-9-3 beats J-J-A-8-7 because the 9 beats the 8.
        //find max pair num
        //if hand1.pair num == hand2.pair num
        
      } else if (hand1.handEnum == TwoPair){
        //A pair consists of two cards of equal rank. In a hand with two pairs, the two pairs are of different ranks (otherwise you would have four of a kind), and there is an odd card to make the hand up to five cards. When comparing hands with two pairs, the hand with the highest pair wins, irrespective of the rank of the other cards - so J-J-2-2-4 beats 10-10-9-9-8 because the jacks beat the tens. If the higher pairs are equal, the lower pairs are compared, so that for example 8-8-6-6-3 beats 8-8-5-5-K. Finally, if both pairs are the same, the odd cards are compared, so Q-Q-5-5-8 beats Q-Q-5-5-4.
        //find higher pair num
        //if higher pair equal
        // compare lower pair
        // if both pair the same the odd cards are compared
        // if odd cards numbers
        // if odd cards nums == cards nums
      } else if (hand1.handEnum == ThreeOfAKind){
        //Three cards of the same rank plus two unequal cards. This combination is also known as Triplets or Trips. When comparing two threes of a kind the rank of the three equal cards determines which is higher. If the sets of three are of equal rank, then the higher of the two remaining cards in each hand are compared, and if those are equal, the lower odd card is compared. So for example 5-5-5-3-2 beats 4-4-4-K-5, which beats 4-4-4-Q-9, which beats 4-4-4-Q-8.
      } else if (hand1.handEnum == Straight) {
        //Five cards of mixed suits in sequence - for example spadeQ-diamondJ-heart10-spade9-club8. When comparing two sequences, the one with the higher ranking top card is better. Ace can count high or low in a straight, but not both at once, so A-K-Q-J-10 and 5-4-3-2-A are valid straights, but 2-A-K-Q-J is not. 5-4-3-2-A, known as a wheel, is the lowest kind of straight, the top card being the five.
      } else if (hand1.handEnum == Flush) {
        //Five cards of the same suit. When comparing two flushes, the highest card determines which is higher. If the highest cards are equal then the second highest card is compared; if those are equal too, then the third highest card, and so on. For example spadeK-spadeJ-spade9-spade3-spade2 beats diamondK-diamondJ-diamond7-diamond6-diamond5 because the nine beats the seven. If all five cards are equal, the flushes are equal.
      } else if (hand1.handEnum == FullHouse) {
        //This combination, sometimes known as a boat, consists of three cards of one rank and two cards of another rank - for example three sevens and two tens (colloquially known as "sevens full of tens" or "sevens on tens"). When comparing full houses, the rank of the three cards determines which is higher. For example 9-9-9-4-4 beats 8-8-8-A-A. If the threes of a kind are equal, the rank of the pairs decides.
      } else if (hand1.handEnum == FourOfAKind) {
        //Four cards of the same rank - such as four queens. The fifth card, known as the kicker, can be anything. This combination is sometimes known as "quads", and in some parts of Europe it is called a "poker", though this term for it is unknown in English. Between two fours of a kind, the one with the higher set of four cards is higher - so 3-3-3-3-A is beaten by 4-4-4-4-2. If two or more players have four of a kind of the same rank, the rank of the kicker decides. For example in Texas Hold'em with heartJ-diamondJ-clubJ-spadeJ-spade9 on the table (available to all players), a player holding K-7 beats a player holding Q-10 since the king beats the queen. If one player holds 8-2 and another holds 6-5 they split the pot, since the 9 kicker makes the best hand for both of them. If one player holds spadeA-club2 and another holds diamondA-diamondK they also split the pot because both have an ace kicker.
      } else if (hand1.handEnum == StraightFlush) {
        //If there are no wild cards, this is the highest type of poker hand: five cards of the same suit in sequence - such as clubJ-club10-club9-club8-club7. Between two straight flushes, the one containing the higher top card is higher. An ace can be counted as low, so heart5-heart4-heart3-heart2-heartA is a straight flush, but its top card is the five, not the ace, so it is the lowest type of straight flush. The highest type of straight flush, A-K-Q-J-10 of a suit, is known as a Royal Flush. The cards in a straight flush cannot "turn the corner": diamond4-diamond3-diamond2-diamondA-diamondK is not valid.
      }
    }
  }

  function card1BeatCard2(Card memory card1, Card memory card2) public returns (CampareResult) {
    if (card1.value == card2){
      return CampareResult.Same;
    }else if (card1.value > card2.value){
      return CampareResult.Bigger;
    } else {
      return CampareResult.Lower;
    }
  }


  function sendEth(address[] memory bettors, uint stack) private {
    uint avgEther = (stack / bettors.length) * (1 - feeRate);
    for(uint i =0; i<bettors.length;i++){
      bettors[i].transfer(avgEther);
    }
  }

  function random() private pure returns (uint) {
    return uint256(keccak256(block.timestamp, block.difficulty));
  }


}