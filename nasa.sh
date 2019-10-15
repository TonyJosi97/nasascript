#!/usr/bin/env bash

scriptCore() {
    strdat=$1                                       # gets the data value into strdata var
    arrDat=(${strdat//-/ })                         # converts the date string to and array

    year=${arrDat[0]}                               # gets the year
    year=${year:2:3}                                # strips off frist 2 char in year
    month=${arrDat[1]}                              # gets month
    day=${arrDat[2]}                                # gets day of the date

    myMonth=${year}${month}                         # combines year and month
    myDate=${year}${month}${day}                    # combines year month and day
    htmlFile='ap'${myDate}'.html.orig'              # constructs the name for the HTML file that will be downloaded
    newHtmlFile='ap'${myDate}'.html'                # constructs name for renaming the html file

    if [ -d "$myDate" ]; then rm -Rf $myDate; fi    # remove the folder for that day if already exists 
    mkdir $myDate
    cd $myDate

    link='https://apod.nasa.gov/apod/ap'${myDate}'.html' # creates the link for the given date

    wget -E -H -k -K -p $link >>../script.log 2>&1 # downloads the site for the given date
    echo

    mv apod.nasa.gov/apod/${htmlFile} .             # move inside the folder
    if mv apod.nasa.gov/apod/image/${myMonth}/* . >>../script.log 2>&1; then
        echo "Good"  >>../script.log 2>&1           # of image file exist then print Good to log
    else
        echo "No Image found on the specified date - "${1}" ... ... ... ___SKIPPING THAT DATE!!!___"
        cd ..                                       # if no image exist return and print error message
        rm -rf ${myDate}
        return
    fi

    mv ${htmlFile} ${newHtmlFile}                   # rename the HTML file

    echo "cat //html/body/p" | xmllint --html --shell ${newHtmlFile} 2>>../script.log | sed '/^\/ >/d' | sed 's/<[^>]*.//g' | awk '
    $1=$1' > extract1.txt                           # extract raw data from the interested parts of the website

    echo $(cat extract1.txt) > extract2.txt         # rename it to extract2

    fold -s -w90 extract2.txt > extract3.txt        # fole -s on the extract file

    sed 's/-------//' extract3.txt > extract4.txt   # remove the trailing - on the data

    rm extract1.txt                                 # remove the temp files
    rm extract2.txt
    rm extract3.txt

    echo "cat //html/body/center/b" | xmllint --html --shell ${newHtmlFile} 2>>../script.log | sed '/^\/ >/d' | sed 's/<[^>]*.//g' | awk '
    $1=$1' > head1.txt                              # extract the credits details

    title="$(head -1 head1.txt)"                    # finds the title of the site
    imageNameJPG=${title}'.jpg'
    imageNameJPEG=${title}'.jpeg'                   # constructs the possible name of the image
    imageNamePNG=${title}'.png'

    rm head1.txt                                    # remove temp files

    for file in *.jpg                               # rename all images to constructed name
    do
    mv "$file" "$imageNameJPG" 2>>../script.log
    done

    for file in *.jpeg
    do
    mv "$file" "$imageNameJPEG" 2>>../script.log    # rename all images to constructed name
    done

    for file in *.png                               # rename all images to constructed name
    do
    mv "$file" "$imageNamePNG" 2>>../script.log
    done

    if [ "$2" == "" ]; then                         # shows download status for minimal info call
        echo 'Downloading --> '${imageNameJPG}'  ...'
    else
        echo 'TITLE: '${title}                      # for other detailed options print the title of the site for that day
        echo >>../script.log 2>&1
    fi

    if [ "$2" == "" ]; then         
        echo >>../script.log 2>&1
    else                                            # for detailed view print the description of image available in the site
        cat extract4.txt
        echo
    fi

    if [ "$2" == "" ]; then
        echo  >>../script.log 2>&1
    else                                            # for detailed view print the credits
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
        imageNameJPG=${3}'.jpg'                     # if user requires to rename the image rename it
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
echo 'Connecting to nasa.gov...'                    # intro connection message 

if [ "$1" == "-d" -a "$3" == "-n" ]; then           # if user wants detailed info along with renaming the output image
    scriptCore $2 _ $4                              # calls the the script core function with arguments

elif [ "$1" == "-d" ]; then                         # if user wants detailed info
    scriptCore $2 _                                 # calls the function 

elif [ "$1" == "-r" ]; then                         # if user wants data in a given range

    strdat1=$2                                      # calculates the number of days from start date till today
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


    cnt2=1                                          # calculates the number of days from end date till today
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


    echo
    for ((diff=$cnt1;diff>=$cnt2;diff--));      # calls the script core funtion past those days from today that are betwenn start and end dates 
    do
        today=$(date -v -${diff}d +%Y-%m-%d)
        echo "Downloading image on --> "$today
        scriptCore $today
    done

elif [ "$1" != "" ]; then                       # calls funtion scriptcore when minimal data or info is required
    scriptCore $1

else                                            # calls help when no arguments are passed to the script
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
echo 'Finished.'                            # prints the finished status

tail -n 500 script.log > newLogfile         # cleans the log file from getting accumulated with higher lines of logs 
rm script.log 
mv newLogfile script.log

echo