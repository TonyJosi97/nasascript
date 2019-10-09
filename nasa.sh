#!/usr/bin/env bash

scriptCore() {
    strdat=$1
    arrDat=(${strdat//-/ })

    year=${arrDat[0]}
    year=${year:2:3}
    month=${arrDat[1]}
    day=${arrDat[2]}

    myMonth=${year}${month}
    myDate=${year}${month}${day}
    htmlFile='ap'${myDate}'.html.orig'
    newHtmlFile='ap'${myDate}'.html'

    if [ -d "$myDate" ]; then rm -Rf $myDate; fi
    mkdir $myDate
    cd $myDate

    link='https://apod.nasa.gov/apod/ap'${myDate}'.html'

    wget -E -H -k -K -p $link >>../script.log 2>&1
    echo

    mv apod.nasa.gov/apod/${htmlFile} .
    if mv apod.nasa.gov/apod/image/${myMonth}/* . >>../script.log 2>&1; then
        echo "Good"  >>../script.log 2>&1
    else
        echo "No Image found on the specified date - "${1}" ... ... ... ___SKIPPING THAT DATE!!!___"
        cd ..
        rm -rf ${myDate}
        return
    fi

    mv ${htmlFile} ${newHtmlFile}

    echo "cat //html/body/p" | xmllint --html --shell ${newHtmlFile} 2>>../script.log | sed '/^\/ >/d' | sed 's/<[^>]*.//g' | awk '
    $1=$1' > extract1.txt

    echo $(cat extract1.txt) > extract2.txt

    fold -s -w90 extract2.txt > extract3.txt

    sed 's/-------//' extract3.txt > extract4.txt

    rm extract1.txt
    rm extract2.txt
    rm extract3.txt

    echo "cat //html/body/center/b" | xmllint --html --shell ${newHtmlFile} 2>>../script.log | sed '/^\/ >/d' | sed 's/<[^>]*.//g' | awk '
    $1=$1' > head1.txt

    title="$(head -1 head1.txt)"
    imageNameJPG=${title}'.jpg'
    imageNameJPEG=${title}'.jpeg'
    imageNamePNG=${title}'.png'

    rm head1.txt

    for file in *.jpg
    do
    mv "$file" "$imageNameJPG" 2>>../script.log
    done

    for file in *.jpeg
    do
    mv "$file" "$imageNameJPEG" 2>>../script.log
    done

    for file in *.png
    do
    mv "$file" "$imageNamePNG" 2>>../script.log
    done

    if [ "$2" == "" ]; then
        echo 'Downloading --> '${imageNameJPG}'  ...'
    else
        echo 'TITLE: '${title}
        echo >>../script.log 2>&1
    fi

    if [ "$2" == "" ]; then
        echo >>../script.log 2>&1
    else
        cat extract4.txt
        echo
    fi

    if [ "$2" == "" ]; then
        echo  >>../script.log 2>&1
    else
        echo "cat //html/body/center" | xmllint --html --shell ${newHtmlFile} 2>>../script.log | sed '/^\/ >/d' | sed 's/<[^>]*.//g' | awk '
        $1=$1' > credit1.txt
        sed -n '/^Image Credit/,/^-------/p' credit1.txt | sed 's/-------//g' |  sed -e "s/&amp;/\&/g" > credit2.txt
        echo $(cat credit2.txt) > credit3.txt
        cat credit3.txt
        echo
        rm credit1.txt
        rm credit2.txt
        rm credit3.txt
    fi

    if [ "$3" == "" ]; then
        echo >>../script.log 2>&1 
    else
        imageNameJPG=${3}'.jpg'
        for file in *.jpg
        do
        mv "$file" ${imageNameJPG} 2>>../script.log
        done
    fi


    mv extract4.txt explanation.txt

    rm -rf apod.nasa.gov
    rm -rf dap.digitalgov.gov
    rm ${newHtmlFile}
    rm explanation.txt

    loc=$(pwd)
    loc=${loc}'/'${imageNameJPG}
    echo 'Image saved as: '${loc}
    echo

    cd ..
}

echo
echo 'Connecting to nasa.gov...'

if [ "$1" == "-d" -a "$3" == "-n" ]; then
    scriptCore $2 _ $4

elif [ "$1" == "-d" ]; then
    scriptCore $2 _

elif [ "$1" == "-r" ]; then

    strdat1=$2
    arrDat1=(${strdat1//-/ })

    year1=${arrDat1[0]}
    year1=${year1:2:3}
    month1=${arrDat1[1]}
    day1=${arrDat1[2]}
    myDate1=${year1}${month1}${day1}

    strdat2=$3
    arrDat2=(${strdat2//-/ })

    year2=${arrDat2[0]}
    year2=${year2:2:3}
    month2=${arrDat2[1]}
    day2=${arrDat2[2]}
    myDate2=${year2}${month2}${day2}

    cnt1=1
    while :
    do
    today=$(date -v -${cnt1}d +%Y%m%d)
    today=${today:2:8}
    if [ $today -eq $myDate1 ] 
    then
        break
    fi
    cnt1=$(($cnt1+1))
    done

    #echo $cnt1

    cnt2=1
    while :
    do
    today=$(date -v -${cnt2}d +%Y%m%d)
    today=${today:2:8}
    if [ $today -eq $myDate2 ] 
    then
        break
    fi
    cnt2=$(($cnt2+1))
    done

    #echo $cnt2

    echo
    for ((diff=$cnt1;diff>=$cnt2;diff--));
    do
        today=$(date -v -${diff}d +%Y-%m-%d)
        echo "Downloading image on --> "$today
        scriptCore $today
    done

elif [ "$1" != "" ]; then
    scriptCore $1

else
    echo
    echo "HELP:
        # sh nasa.sh date[ in yyyy-mm--dd format ] --> Downloads image of the given date
        # sh nasa.sh -d date[ in yyyy-mm--dd format ] --> Downloads the title, explanation text and credits
        # sh nasa.sh -d date[ in yyyy-mm--dd format ] -n [ name ] --> Downloads the title, explanation text 
            and credits, and saves the image in the given [ name ]
        # sh nasa.sh -r date1[ old date in yyyy-mm--dd format ] date2[ new in yyyy-mm--dd format ] --> Download all images 
            posted between the two dates [MAX = 10 days]"
    echo
fi

echo
echo 'Finished.'

tail -n 500 script.log > newLogfile
rm script.log 
mv newLogfile script.log

echo