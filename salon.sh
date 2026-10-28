
#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon -q -t -A -c"

SERVICES=$($PSQL "SELECT service_id || ') ' || name FROM services ORDER BY service_id;")

SHOW_SERVICES() {
  printf '%s\n' "$SERVICES"
}

printf '\n~~~~~ MY SALON ~~~~~\n\n'
printf 'Welcome to My Salon, how can I help you?\n\n'

SHOW_SERVICES

while true
do
  read SERVICE_ID_SELECTED || exit 0

  case "$SERVICE_ID_SELECTED" in
    ''|*[!0-9]*)
      SERVICE_NAME=""
      ;;
    *)
      SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
      ;;
  esac

  if [ -n "$SERVICE_NAME" ]
  then
    break
  fi

  printf '\nI could not find that service. What would you like today?\n'
  SHOW_SERVICES
done

printf "\nWhat's your phone number?\n"
read CUSTOMER_PHONE || exit 0

PHONE_SQL=$(printf '%s' "$CUSTOMER_PHONE" | sed "s/'/''/g")

CUSTOMER_RECORD=$($PSQL "SELECT customer_id || '|' || name FROM customers WHERE phone = '$PHONE_SQL';")

if [ -z "$CUSTOMER_RECORD" ]
then
  printf "\nI don't have a record for that phone number, what's your name?\n"
  read CUSTOMER_NAME || exit 0

  NAME_SQL=$(printf '%s' "$CUSTOMER_NAME" | sed "s/'/''/g")

  CUSTOMER_ID=$($PSQL "INSERT INTO customers(phone, name) VALUES('$PHONE_SQL', '$NAME_SQL') RETURNING customer_id;")

  if [ -z "$CUSTOMER_ID" ]
  then
    printf 'Unable to register customer.\n'
    exit 1
  fi
else
  CUSTOMER_ID=${CUSTOMER_RECORD%%|*}
  CUSTOMER_NAME=${CUSTOMER_RECORD#*|}
fi

printf '\nWhat time would you like your %s, %s?\n' "$SERVICE_NAME" "$CUSTOMER_NAME"
read SERVICE_TIME || exit 0

TIME_SQL=$(printf '%s' "$SERVICE_TIME" | sed "s/'/''/g")

if $PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$TIME_SQL');"
then
  printf '\nI have put you down for a %s at %s, %s.\n' "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"
else
  printf 'Unable to create appointment.\n'
  exit 1
fi

exit 0
