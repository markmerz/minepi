# minepi
Implementation of MINEPI algorithm in perl

I'm publishing my old work: partial minepi algorithm implementation in perl. It is partial in a sense that it only implements sequential episode part of the algorithm and does not support parallel episodes e.q. it assumes that every event must have different timestamp. Also it assumes that timestamps are full integers.

Format for input file is:
timestamp:event
timestamp:event
...

as in

1:A
2:B
3:A
4:B

and so on..

I used the algorithm for automatic generation of regexp patterns for log analysis. Idea was that it finds all different types of log messages by itself and makes it easier to analyze variable parts of messages.

Sorry for perl. It was the language choice of sysadmins back in the old days :). I ran into sequential mining problem again in 2019 and thought that by this time someone has published better version for MINEPI. It wasn't the case so I revived my old implementation from dusty archive.

-- 
Markko Merzin <markko.merzin@gmail.com>

