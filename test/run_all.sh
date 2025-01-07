#!/usr/bin/env bash

FAILD_TEST=""
for test in $( find . -name '*_test.sh' ); do
    echo "------------ Running TEST $test -------------"
    ../bin/bashunit $test || FAILD_TEST="$FAILD_TEST\n$test"
    echo
done

echo "------------ FAILD TEST -------------"
echo -e "$FAILD_TEST"
