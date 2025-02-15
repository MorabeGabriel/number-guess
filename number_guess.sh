#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

INPUT_NAME() {
  echo "Enter your username:"
  read NAME
  n=${#NAME}

  # Validate username length
  if [[ ! $n -le 22 ]] || [[ ! $n -gt 0 ]]
  then
    INPUT_NAME
  else
    # Fetch user data
    USER_DATA=$($PSQL "SELECT user_id, username, frequent_games FROM users WHERE username='$NAME';")

    if [[ -n $USER_DATA ]]
    then
      # Extract user information
      USER_ID=$(echo "$USER_DATA" | cut -d '|' -f1)
      USER_NAME=$(echo "$USER_DATA" | cut -d '|' -f2)
      GAME_PLAYED=$(echo "$USER_DATA" | cut -d '|' -f3)

      # Get the best game (minimum guesses)
      BEST_GAME=$($PSQL "SELECT MIN(best_guess) FROM games WHERE user_id=$USER_ID;")
      if [[ -z $BEST_GAME ]]; then
        BEST_GAME="N/A"
      fi

      # ✅ Correct Welcome Message for Returning Users
      echo "Welcome back, $USER_NAME! You have played $GAME_PLAYED games, and your best game took $BEST_GAME guesses."

    else
      # ✅ Correct Message for New Users
      USER_NAME=$NAME
      echo "Welcome, $USER_NAME! It looks like this is your first time here."
      $PSQL "INSERT INTO users(username, frequent_games) VALUES('$USER_NAME', 0);"
    fi

    # Start game
    CORRECT_ANSWER=$(( $RANDOM % 1000 + 1 ))
    GUESS_COUNT=0
    INPUT_GUESS $USER_NAME $CORRECT_ANSWER $GUESS_COUNT
  fi
}


INPUT_GUESS() {
  USER_NAME=$1
  CORRECT_ANSWER=$2
  GUESS_COUNT=$3
  USSER_GUESS=$4

  if [[ -z $USSER_GUESS ]]
  then
    echo "Guess the secret number between 1 and 1000:"
    read USSER_GUESS
  else
    echo "That is not an integer, guess again:"
    read USSER_GUESS
  fi

  GUESS_COUNT=$(( $GUESS_COUNT + 1 ))
  if [[ ! $USSER_GUESS =~ ^[0-9]+$ ]]
  then
    INPUT_GUESS $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USSER_GUESS
  else
    CHECK_ANSWER $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USSER_GUESS
  fi
}

CHECK_ANSWER() {
  USER_NAME=$1 
  CORRECT_ANSWER=$2 
  GUESS_COUNT=$3
  USSER_GUESS=$4
  
  if [[ $USSER_GUESS -lt $CORRECT_ANSWER ]]
  then
    echo "It's higher than that, guess again:"
    read USSER_GUESS
  elif [[ $USSER_GUESS -gt $CORRECT_ANSWER ]]
  then
    echo "It's lower than that, guess again:"
    read USSER_GUESS
  else
    GUESS_COUNT=$GUESS_COUNT
  fi

  GUESS_COUNT=$(( $GUESS_COUNT + 1 ))
  if [[ ! $USSER_GUESS =~ ^[0-9]+$ ]]
  then
    INPUT_GUESS $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USSER_GUESS
  elif [[ $USSER_GUESS -lt $CORRECT_ANSWER ]] || [[ $USSER_GUESS -gt $CORRECT_ANSWER ]]
  then
    CHECK_ANSWER $USER_NAME $CORRECT_ANSWER $GUESS_COUNT $USSER_GUESS
  elif [[ $USSER_GUESS -eq $CORRECT_ANSWER ]]
  then
    SAVE_USER $USER_NAME $GUESS_COUNT
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $CORRECT_ANSWER. Nice job!"
    exit 0
  fi
}

SAVE_USER() {
  USER_NAME=$1 
  GUESS_COUNT=$2

  CHECK_NAME=$($PSQL "SELECT username FROM users WHERE username='$USER_NAME';")
  if [[ -z $CHECK_NAME ]]
  then
    INSERT_NEW_USER=$($PSQL "INSERT INTO users(username, frequent_games) VALUES('$USER_NAME',1);")
  else
    GET_GAME_PLAYED=$(( $($PSQL "SELECT frequent_games FROM users WHERE username='$USER_NAME';") + 1))
    UPDATE_EXIST_USER=$($PSQL "UPDATE users SET frequent_games=$GET_GAME_PLAYED WHERE username='$USER_NAME';")
  fi
  SAVE_GAME $USER_NAME $GUESS_COUNT
}

SAVE_GAME() {
  USER_NAME=$1 
  NUMBER_OF_GUESSES=$2

  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USER_NAME';")
  INSERT_GAME=$($PSQL "INSERT INTO games(user_id, best_guess) VALUES($USER_ID, $NUMBER_OF_GUESSES);")
}

INPUT_NAME
