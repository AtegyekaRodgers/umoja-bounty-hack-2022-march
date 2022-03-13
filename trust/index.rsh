'reach 0.1';

const [isHand, ROCK, PAPER, SCISSORS] = makeEnum(3);
const [isOutcome, B_WINS, DRAW, A_WINS] = makeEnum(3);

const winner = (alicezHand, bobzHand) => ((alicezHand + (4 - bobzHand)) % 3);

assert(winner(ROCK, PAPER) == B_WINS);
assert(winner(PAPER, ROCK) == A_WINS);
assert(winner(ROCK, ROCK) == DRAW);

forall(UInt, alicezHand =>
    forall(UInt, bobzHand =>
        assert(isOutcome(winner(alicezHand, bobzHand)))
    )
);

forall(UInt, (hand) => assert(winner(hand, hand) == DRAW));

const Player = {
    ...hasRandom,
    getHand: Fun([], UInt),
    seeOutcome: Fun([UInt], Null),
    informTimeout: Fun([], Null),
};

export const main = Reach.App(() => {
    const Alice = Participant('Alice', {
        ...Player,
        wager: UInt, // atomic units of currency
        deadline: UInt, // time delta (blocks/rounds)
    });
    const Bob = Participant('Bob', {
        ...Player,
        acceptWager: Fun([UInt], Null),
    });
    init();
});

const informTimeout = () => {
    each([Alice, Bob], () => {
        interact.informTimeout();
    });
};

Alice.only(() => {
    const wager = declassify(interact.wager);
    const _handOfAlice = interact.getHand();
    const [_commitmentByAlice, _saltOfAlice] = makeCommitment(interact, _handOfAlice);
    const commitmentByAlice = declassify(_commitmentByAlice);
    const deadline = declassify(interact.deadline);
});
Alice.publish(wager, commitmentByAlice, deadline).pay(wager);
commit();

unknowable(Bob, Alice(_handOfAlice, _saltOfAlice));
Bob.only(() => {
    interact.acceptWager(wager);
    const bobzHand = declassify(interact.getHand());
});
Bob.publish(bobzHand).pay(wager).timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));;
commit();

Alice.only(() => {
    const alicezSalt = declassify(_saltOfAlice);
    const alicezHand = declassify(_handOfAlice);
});
Alice.publish(alicezSalt, alicezHand).timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));;
checkCommitment(commitmentByAlice, alicezSalt, alicezHand);

const outcome = winner(alicezHand, bobzHand);
const [forAlice, forBob] = outcome == A_WINS ? [2, 0] : outcome == B_WINS ? [0, 2] : [1, 1];
transfer(forAlice * wager).to(Alice);
transfer(forBob * wager).to(Bob);
commit();
each([Alice, Bob], () => {
    interact.seeOutcome(outcome);
});