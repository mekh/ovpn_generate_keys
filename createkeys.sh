#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Not full parametrs line defined. Use: $0 <username> <full user name> <e-mail>"
    exit $?
fi

export KEY_COUNTRY="UA"
export KEY_PROVINCE="Kiev"
export KEY_CITY="Kiev"
export KEY_ORG="company.ltd"
export KEY_CN="$1"
export KEY_NAME="$2"
export KEY_EMAIL="$3"
export KEY_OU=""

openssl req -batch -new -nodes -keyout keys/K"$1".pem -out req/R"$1".pem -config openssl.cnf
openssl ca -batch -config openssl.cnf -out certs/C"$1".pem -infiles req/R"$1".pem

sed -e "s/Client/$1/g" config/default.ovpn > config/eh.ovpn
echo 'push "route 192.168.3.0 255.255.255.0"' > ccd/$1

PASS=$(tr -dc '[:alnum:]' < /dev/urandom | fold -w 16 | head -n1 )

echo "\n----------------------------\n"
echo "Passowrd is: $PASS"
echo "\n----------------------------\n"
echo "$(date) $1 $PASS" >> pass.txt

rar a -apconfig -ep -hp"$PASS" -m5 "$1".rar certs/C"$1".pem keys/K"$1".pem config/eh.ovpn CA_cert.pem ta.key

echo -n "Do you want to send an e-mail to $3? [y/n] "
read choise
case "$choise" in
    [nN]) echo -n "Do you want to send an e-mail to other address? [y/n] "
        read choise2
        case "$choise2" in
            [nN]) echo "Good bye!"
                exit $?
            ;;
            [yY]) echo -n "Enter e-mail address: "
                read EMAIL
                echo "\nNew e-mail has been sent to "$EMAIL""
            ;;
            *) echo "You didn't chose the right answer. Good by!"
            ;;
        esac
    ;;
    [yY]) EMAIL=$3
        echo "\nNew mail has been sent to $EMAIL"
    ;;
        *) echo "You didn't chose the right answer. Good by!"
    exit $?
    ;;
esac

echo -e "Good day! \nCall your system administator for any further assistace.\n\n--\
     \nBest regards,\nCompany Servers' Administrator." | mutt -s "Company" -a $1.rar $EMAIL
