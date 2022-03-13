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

    const informTimeout = () => {
        each([Alice, Bob], () => {
            interact.informTimeout();
        });
    };

    Alice.only(() => {
        const wager = declassify(interact.wager);
        const deadline = declassify(interact.deadline);
    });
    Alice.publish(wager, deadline).pay(wager);
    commit();

    Bob.only(() => {
        interact.acceptWager(wager);
    });
    Bob.pay(wager).timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));

    var outcome = DRAW;
    invariant(balance() == 2 * wager && isOutcome(outcome));
    while (outcome == DRAW) {
        commit();
        Alice.only(() => {
            const _handOfAlice = interact.getHand();
            const [_commitmentByAlice, _saltOfAlice] = makeCommitment(interact, _handOfAlice);
            const commitmentByAlice = declassify(_commitmentByAlice);
        });
        Alice.publish(commitmentByAlice).timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));
        commit();

        unknowable(Bob, Alice(_handOfAlice, _saltOfAlice));
        Bob.only(() => {
            const handBob = declassify(interact.getHand());
        });
        Bob.publish(handBob).timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));
        commit();

        Alice.only(() => {
            const alicezSalt = declassify(_saltOfAlice);
            const alicezHand = declassify(_handOfAlice);
        });
        Alice.publish(alicezSalt, alicezHand).timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));
        checkCommitment(commitmentByAlice, alicezSalt, alicezHand);

        const outcome = winner(alicezHand, bobzHand);
        continue;
    }

    assert(outcome == A_WINS || outcome == B_WINS);
    transfer(2 * wager).to(outcome == A_WINS ? Alice : Bob);
    commit();

    each([Alice, Bob], () => {
        interact.seeOutcome(outcome);
    });

});