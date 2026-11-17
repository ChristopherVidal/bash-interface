#!/bin/bash

#Author: Christopher Vidal


rm -f final_project_database.db

sqlite3 final_project_database.db <<EOF
.read db_assembly.sql
EOF


USER_INTERFACE () {
        OPTION_SELECTED=-1

        SHOW_MAIN_MENU_OPTIONS () {
            echo "\n~~MAIN MENU~~\n What would you like to do today?\n"
            PROGRAM_OPTIONS="[1] search for store specific information\n"
            PROGRAM_OPTIONS+="[2] search for order by ID \n"
            PROGRAM_OPTIONS+="[3] search for a specific product by ID\n"
            echo $PROGRAM_OPTIONS;
        }

        SHOW_STORE_SPECIFIC_OPTIONS () {
            echo "\n What are you interested in? \n"
            PROGRAM_OPTIONS="[1] basic store info \n"
            PROGRAM_OPTIONS+="[2] orders\n"
            PROGRAM_OPTIONS+="[3] products offered\n"
            echo $PROGRAM_OPTIONS
        }

        SHOW_MAIN_MENU_OPTIONS
        echo "Select a number from the list: \c"
        read OPTION_SELECTED

        until [[ $OPTION_SELECTED =~ ^\[?[1-3]\]?$ ]]
        do
            echo "\nTHIS IS NOT A VALID OPTION. HIT ENTER TO TRY AGAIN."
            read CONTINUE
            echo "---"
            SHOW_MAIN_MENU_OPTIONS
            echo "Select a number from the list: \c"
            read OPTION_SELECTED
        done

        if [[ $OPTION_SELECTED =~  ^\[?1\]?$ ]]
        then

            echo "Enter the store code: \c"
            read INPUT_STORE_CODE

            until  [[ $INPUT_STORE_CODE =~ ^[0-9]+$ && -n $(sqlite3 final_project_database.db <<EOF
select code from location where code=$INPUT_STORE_CODE;
EOF
                ) ]]
                do
                    echo "INVALID STORE CODE. HIT ENTER TO TRY AGAIN.\c"
                    read CONTINUE
                    echo "---"
                    echo "Enter the store code: \c"
                    read INPUT_STORE_CODE
                done

            SHOW_STORE_SPECIFIC_OPTIONS
            echo "Select a number from the list: \c"
            read OPTION_SELECTED

            #insist that user chooses a number listed
            until [[ $OPTION_SELECTED =~ ^\[?[1-3]\]?$ ]]
            do
                echo "INVALID OPTION. HIT ENTER TO TRY AGAIN. \c"
                read CONTINUE
                echo "---"
                read OPTION_SELECTED
            done

            #user wants to see basic store information
            if [[ $OPTION_SELECTED =~ ^\[?1\]?$ ]]
            then
                RESULTS=$(sqlite3 final_project_database.db <<EOF
select code, storeManager, city, phoneNum from location where code=$INPUT_STORE_CODE;
EOF
                )

            echo "$RESULTS" | while IFS="|" read CODE STOREMANAGER CITY PHONENUM
            do
                echo "\nBASIC STORE $CODE INFO:"
                echo "Store Manager: $STOREMANAGER"
                echo "City: $CITY"
                echo "Phone Number: $PHONENUM"
            done

            #user wants to see orders for a given store
            elif [[ $OPTION_SELECTED =~ ^\[?2\]?$ ]]
            then
                RESULTS=$(sqlite3 final_project_database.db <<EOF
select orderId, datePlaced, dateFinalized from productOrder where destination=$INPUT_STORE_CODE;
EOF
                )
                echo "\nORDERS FOR STORE $INPUT_STORE_CODE:\n"
                echo "$RESULTS" | while IFS="|" read ORDERID DATEPLACED DATEFINALIZED
                do
                    echo "Order Id:$ORDERID, Date Placed:$DATEPLACED, Date Finalized: $DATEFINALIZED"
                done

                SEE_CONTENTS="Y"
                until [[ "$SEE_CONTENTS" != "Y" && "$SEE_CONTENTS" != "y" ]]
                do
                    echo "\nDo you wish to see the contents of one of the orders listed above?"
                    echo "Hit [Y] if yes, or any other key if not: \c"
                    read SEE_CONTENTS
                    if [[ "$SEE_CONTENTS" == "Y" || "$SEE_CONTENTS" == "y" ]]
                    then
                        echo "\nWhat was the ID?"
                        read ORDER_FOR_THE_STORE

                        until [[ $ORDER_FOR_THE_STORE =~ ^[0-9]+$ ]]
                        do
                            echo "\nTHIS IS NOT A VALID ORDER. HIT ENTER TO TRY AGAIN."
                            read CONTINUE
                            echo "---"
                            echo "What was the ID of the order?: \c"
                            read ORDER_FOR_THE_STORE
                        done

                        ORDER_CONTENTS=$(sqlite3 final_project_database.db <<EOF
select prodId, name, prodUnits from consists_of natural join product where orderNum=$ORDER_FOR_THE_STORE and orderNum in (select orderId from productOrder where destination=$INPUT_STORE_CODE);
EOF
                        )
                        if [[ -z $ORDER_CONTENTS ]]
                        then
                            echo "This order doesn't belong to this store or simply doesn't exist."
                        else

                        echo "\nCONTENTS OF ORDER WITH ID $ORDER_FOR_THE_STORE:\n"
                        echo "$ORDER_CONTENTS" | while IFS="|" read PRODID NAME PRODUNITS
                        do
                            echo "Product ID: $PRODID, Product Name: $NAME, Units in Order: $PRODUNITS"
                        done
                        fi
                    fi
                done

            #user wants to see products offered at a location
            elif [[ $OPTION_SELECTED =~ ^\[?3\]?$ ]]
            then
                PRODUCT_RESULTS=$(sqlite3 final_project_database.db <<EOF
select offers.prodId, name, sellingPrice from offers natural join product where locId=$INPUT_STORE_CODE
EOF
                )

                echo "PRODUCTS OFFERED AT STORE $INPUT_STORE_CODE"

                echo "$PRODUCT_RESULTS" | while IFS="|" read PRODID NAME SELLINGPRICE
                do
                    echo "Product ID: $PRODID, Product Name: $NAME, PRICE: $SELLINGPRICE"
                done
            fi


        elif [[ $OPTION_SELECTED =~ ^\[?2\]?$ ]]
        then
            echo "Enter the ID for the order:"
            read SPECIFIC_ORDER_ID

            echo "SEARCH RESULT:"

        elif [[ $OPTION_SELECTED =~ ^\[?3\]?$ ]]
        then
            echo "Enter the ID for the product:"
            read SPECIFIC_PRODUCT_ID

            echo "SEARCH RESULT:"
        fi

}

# the user can break out of the loop by selecting Y/y at the prompt
RETURN_TO_MAIN_MENU="Y"
until [[ $RETURN_TO_MAIN_MENU != "Y" && $RETURN_TO_MAIN_MENU != "y" ]]
do
    USER_INTERFACE
    echo "Return to Main Menu?"
    echo "Hit [Y] for yes, hit anything else if not"
    read RETURN_TO_MAIN_MENU
done


