#!/usr/bin/env bash


function hostname-test() {
hst=`hostname -s`

case $hst in
  (nginx-*) echo "Woohoo, we're on nginx!";;
  (web-*) echo "Oops, web? Are you kidding?";;
  (*)   echo "How did I get in the middle of nowhere?";;
esac

} >/home/ryan/test.log 2>&1

hostname-test 