#!/bin/bash
#Jack Denton 260948222


#Error mesage helper function
errorMsg(){
	echo "Error: $1"	
	echo "Script syntax: ./covidata.sh -r procedure id range inputFile outputFile compareFile"
	Str=$'Legal usage examples:\n		./covidata.sh get 35 data.csv result.csv\n		./covidata.sh -r get 35 2020-01 2020-03 data.csv result.csv\n		./covidata.sh compare 10 data.csv result2.csv result.csv\n		./covidata.sh -r compare 10 2020-01 2020-03 data.csv result2.csv result.csv' 
	echo "$Str"
}





#Given two dates in year-month form it creates a file containing all dates within the range
getDates() {
x=$1
year=${x:0:4}
month=${x:5:2} 

y=$2
a=${y:0:4}
b=${y:5:2} 

startPoint=$1
endPoint=$2

if [[ "$b" -eq 12 ]]
then
        ((a=a+1))
        b="01"
        endPoint="$a-$b"
else
        ((b=b+1))
        endPoint="$a-0$b"
fi


monthCounter=$month
while [ "$startPoint" != "$endPoint" ]; do

        counter=1
        while [ $counter -lt 32 ]; do

                if [[ $counter -lt 10 ]]
                then
                        pt1=${startPoint:0:8}
                        pt2="0$counter"
                        newdate="$pt1-$pt2"
                        ((counter=counter+1))

                else
                        pt1=${startPoint:0:8}
                        pt2="$counter"
                        newdate="$pt1-$pt2"
                        ((counter=counter+1))

                fi
  		
		if [[ ${#newdate} != 2 ]] && [[ counter -le 15 ]]
                then

                        echo $newdate >> firstdates.txt
                fi

                if [[ ${#newdate} != 2 ]] && [[ counter -ge 16 ]]
                then

                        echo $newdate >> seconddates.txt
                fi

        done
        counter=0

        if [[ $monthCounter -eq 12 ]]
        then
                year=${startPoint:0:4}
                ((year=year+1))
                newdate="$year-00"
                startPoint=$newdate
                monthCounter=0

        fi

        if [[ $monthCounter -lt 10 ]]
        then
                pt1=${startPoint:0:5}
                ((monthCounter=monthCounter+1))
                pt2="0$monthCounter"
                #pt3=${startpoint:8:2}
                newdate="$pt1$pt2"
                startPoint=$newdate

        else
                pt1=${startPoint:0:5}
                ((monthCounter=monthCounter+1))
                pt2="$monthCounter"
                newdate="$pt1$pt2"
                startPoint=$newdate
        fi

done

}







#Checks number of arguments 
if [[ $1 = "-r" ]]
then 
	if [[ $2 != "get" ]]  && [[ $2 != "compare" ]]
	then 
		errorMsg "Procedure not provided"
		exit 1
	elif [[ $2 = "get" ]] && [[ $# != 7 ]]
	then 
		errorMsg "Wrong number of arguments"
		exit 1
	elif [[ $2 = "compare" ]] && [[ $# != 8 ]]
        then
                errorMsg "Wrong number of arguments"
		exit 1
	fi
else 
	if [[ $1 != "get" ]]  && [[ $1 != "compare" ]]
        then
                errorMsg "Procedure not provided"
		exit 1
	elif [[ $1 = "get" ]] && [[ $# != 4 ]]
        then
                errorMsg "Wrong number of arguments"
		exit 1
	elif [[ $1 = "compare" ]] && [[ $# != 5 ]]
        then
                errorMsg "Wrong number of arguments"
		exit 1
        fi
fi


if [[ $1 = "get" ]]
then
	#Checks that input file name does exist 
	if [[ ! -f $3 ]]
	then
		errorMsg "Input file name does not exist"
		exit 1
	fi

	#Sets the script parameters as variables
	id=$2
	resultFile=$4
	intialFile=$3
	#checks if the first comlumn contains the id and writes it into the new file if it does
	 awk -v a=$id -v b=$resultFile -v c=$initialFile '
	 BEGIN {FS = ","}
	 { if ($1 == a){print $0 > b}}' < $3

	
		 
	echo "rowcount,avgconf,avgdeaths,avgtests"  >> $4	
	

	awk -v d=$4 'BEGIN {FS = ","}{sum1 += $6}{sum2 += $8}{sum3 += $11}END {NR = NR-1
       	OFS = ","
	print NR,sum1/NR,sum2/NR,sum3/NR >> d}' < $4

fi

if [[ $1 = "compare" ]] 
then
	#Checks that input file name does exist 
        if [[ ! -f $3 ]]
        then
                errorMsg "Input file name does not exist"
                exit 1
        fi

        #Sets the script parameters as variables
        id=$2
        resultFile=$4
        intialFile=$3
        #checks if the first comlumn contains the id and writes it into the new file if it does
         awk -v a=$id -v b=$resultFile -v c=$initialFile '
         BEGIN {FS = ","}
  	 { if ($1 == a){print $0 > b}}' < $3	

	#Creates a temp file for stats
	echo "rowcount,avgconf,avgdeaths,avgtests"  > temp.txt

	#Writes stats into temp file
        awk -v d=$4 'BEGIN {FS = ","}{sum11 += $6}{sum22 += $8}{sum33 += $11}END {
        OFS = ","
        print NR,sum11/NR,sum22/NR,sum33/NR >> "temp.txt"}' < $4

	echo "rowcount,avgconf,avgdeaths,avgtests"  >> temp.txt
	#Writes the comp file stats into the temp.txt file
	tail -1 $5 >> temp.txt

	#Writes the comp file without stats into the output file
	head -n -2 $5 >> $4

	#Currently have a output file with all the stats and a temp text file with both stats in it just need to compare the two stats now, will be in row 2 and 4 of temp.txt
	echo "difcount,difavgconf,difavgdeaths,difavgtests"  >> temp.txt

	awk 'BEGIN {FS = ","}{ if (NR == 2){
	sum1 += $1
	sum2 += $2
	sum3 += $3
	sum4 += $4
	}}{ if (NR == 4){
        sum1 -= $1
        sum2 -= $2
        sum3 -= $3
        sum4 -= $4
        }} 
	END {
	OFS = ","
	print sum1,sum2,sum3,sum4 >> "temp.txt"}' < temp.txt


	cat temp.txt >> $4

	rm temp.txt
fi


if [[ $1 = -r ]] && [[ $2 = "get" ]]
then
#Checks that input file name does exist 
        if [[ ! -f $6 ]]
        then
                errorMsg "Input file name does not exist"
                exit 1
        fi


        getDates $4 $5

        while read l; do
                grep "$l" $6 >> newdata1.txt
        done < firstdates.txt

          while read l; do
                grep "$l" $6 >> newdata2.txt
        done < seconddates.txt


        #Sets the script parameters as variables
        id=$3
        resultFile=$7
        intialFile=$6
        #checks if the first comlumn contains the id and writes it into the new file if it does
         awk -v a=$id -v b=tempfile1.txt '
         BEGIN {FS = ","}
         { if ($1 == a){print $0 > b}}' < newdata1.txt

        #checks if the first comlumn contains the id and writes it into the new file if it does
         awk -v a=$id -v b=tempfile2.txt '
         BEGIN {FS = ","}
         { if ($1 == a){print $0 > b}}' < newdata2.txt


        echo "rowcount,avgconf,avgdeaths,avgtests"  >> tempstats.txt


        awk -v y=tempstats.txt 'BEGIN {FS = ","}{sum1 += $6}{sum2 += $8}{sum3 += $11}END {
        OFS = ","
        print NR,sum1/NR,sum2/NR,sum3/NR >> y}' < tempfile1.txt


        awk -v y=tempstats.txt 'BEGIN {FS = ","}{sum1 += $6}{sum2 += $8}{sum3 += $11}END {
        OFS = ","
        print NR,sum1/NR,sum2/NR,sum3/NR >> y}' < tempfile2.txt


 cat tempfile2.txt >> tempfile1.txt

        cat tempstats.txt >> tempfile1.txt

        cat tempfile1.txt >> $7

        rm tempfile1.txt
        rm tempfile2.txt
        rm tempstats.txt
        rm newdata1.txt
        rm newdata2.txt
        rm firstdates.txt
        rm seconddates.txt
fi

if [[ $1 = -r ]] && [[ $2 = "compare" ]]
then
	#Checks that input file name does exist
        if [[ ! -f $6 ]]
        then
                errorMsg "Input file name does not exist"
                exit 1
        fi
	
	getDates $4 $5

        while read l; do
                grep "$l" $6 >> newdata1.txt
        done < firstdates.txt

          while read l; do
                grep "$l" $6 >> newdata2.txt
        done < seconddates.txt


        #Sets the script parameters as variables
        id=$3
        resultFile=$7
        intialFile=$6
         #checks if the first comlumn contains the id and writes it into the new file if it does
         awk -v a=$id -v b=tempfile1.txt '
         BEGIN {FS = ","}
         { if ($1 == a){print $0 > b}}' < newdata1.txt

         #checks if the first comlumn contains the id and writes it into the new file if it does
         awk -v a=$id -v b=tempfile2.txt '
         BEGIN {FS = ","}
         { if ($1 == a){print $0 > b}}' < newdata2.txt


        echo "rowcount,avgconf,avgdeaths,avgtests"  >> tempstats.txt

        awk -v y=tempstats.txt 'BEGIN {FS = ","}{sum1 += $6}{sum2 += $8}{sum3 += $11}END {
        OFS = ","
        print NR,sum1/NR,sum2/NR,sum3/NR >> y}' < tempfile1.txt

        awk -v y=tempstats.txt 'BEGIN {FS = ","}{sum1 += $6}{sum2 += $8}{sum3 += $11}END {
        OFS = ","
        print NR,sum1/NR,sum2/NR,sum3/NR >> y}' < tempfile2.txt

        cat tempfile2.txt >> tempfile1.txt


        cat tempfile1.txt >> $7



        rm tempfile1.txt
        rm tempfile2.txt
        rm newdata1.txt
        rm newdata2.txt
        rm firstdates.txt
        rm seconddates.txt

	tail -3 $8 >> tempstats.txt

	head -n -3 $8 >> $7

	

	echo "difcount,difavgconf,difavgdeaths,difavgtests"  >> tempstats.txt
	
	awk 'BEGIN {FS = ","}{ if (NR == 2){
        sum1 += $1
        sum2 += $2
        sum3 += $3
        sum4 += $4
        }}{ if (NR == 5){
        sum1 -= $1
        sum2 -= $2
        sum3 -= $3
        sum4 -= $4
        }} 
        END {
        OFS = ","
        print sum1,sum2,sum3,sum4 >> "tempstats.txt"}' < tempstats.txt

	awk 'BEGIN {FS = ","}{ if (NR == 3){
        sum1 += $1
        sum2 += $2
        sum3 += $3
        sum4 += $4
        }}{ if (NR == 6){
        sum1 -= $1
        sum2 -= $2
        sum3 -= $3
        sum4 -= $4
        }}
        END {
        OFS = ","
        print sum1,sum2,sum3,sum4 >> "tempstats.txt"}' < tempstats.txt


	cat tempstats.txt >> $7

	rm tempstats.txt
		
fi 


