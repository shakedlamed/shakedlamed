$R={$D,$K=$ARgs;$S=0..255;0..255|%{$J=($J+$S[$_]+$K[$_%$K.COUNT])%256;$S[$_],$S[$J]=$S[$J],$S[$_]};
$D|%{$I=($I+1)%256;
$H=($H+$S[$I])%256;
$S[$I],$S[$H]=$S[$H],$S[$I];
