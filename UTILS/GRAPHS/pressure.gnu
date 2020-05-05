reset
set termoption enhanced
#set encoding utf8
#set term post eps solid size 6,4 font "Times-Roman,20"
#set term pdfcairo enhanced size 600,400 font "Times-Roman,14"
set term pngcairo size 600,400 font "Times-Roman,10" enhanced
set output "pressao.png"
#set style arrow 1 lc rgb "red" lt 1 lw 1 nohead
set style line 2 lc rgb "black" lt 1 lw 1
#set xrange [300:400]
set xlabel "Tempo (ps)"
#set yrange [0:1000]
set ylabel "Temperatura (K)"
#set arrow from 0,371.43 to 100,371.43 arrowstyle 1 front
plot "temperatura-4.dat" u 1:2 w l ls 2 notitle
