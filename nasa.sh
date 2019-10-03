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
    mv apod.nasa.gov/apod/image/${myMonth}/* .
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
        echo
    fi

    if [ "$2" == "" ]; then
        echo 
    else
        cat extract4.txt
        echo
    fi

    if [ "$2" == "" ]; then
        echo 
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
        echo 
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
elif [ "$1" != "" ]; then
    scriptCore $1
else
    echo
    echo "HELP:
        # sh nasa.sh date[ in yyyy-mm--dd format ] --> Downloads image of the given date
        # sh nasa.sh -d date[ in yyyy-mm--dd format ] --> Downloads the title, explanation text and credits
        # sh nasa.sh -d date[ in yyyy-mm--dd format ] -n [ name ] --> Downloads the title, explanation text 
            and credits, and saves the image in the given [ name ]
        # sh nasa.sh -r date1[ in yyyy-mm--dd format ] date2[ in yyyy-mm--dd format ] --> Download all images 
            posted between the two dates [MAX = 10 days]"
    echo
fi
echo 'Finished.'

tail -n 500 script.log > newLogfile
rm script.log
mv newLogfile script.log

echo