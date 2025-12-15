pdf_dc(){
  # Usage: pdf_dc [password] <input.pdf>
  # If password is ommitted, it defaults to: 1144095880
  # If password is provided, it will be used to decrypt the input file
  # If the output file already exists, it will be overwritten
  # If the input file is not found, it will return an error
  # If the output file is not created, it will return an error
  # If the decryption fails, it will return an error
  # If the decryption is successful, it will return a success message
  # If the decryption is successful, it will return a success message
  local DEFAULT_PASSWORD="1144095880"
  local PASSWORD
  local INPUT_FILE
  local OUTPUT_FILE

  ### --- Argument Handling ---
  if [ -n "$1" ] && [ -z "$2" ]; then
    # Case: pdf_dc <input.pdf> (using default password);
    PASSWORD="$DEFAULT_PASSWORD"
    INPUT_FILE="$1"
  elif [ -n "$1" ] && [ -n "$2" ]; then
    # Case: pdf_dc <password> <input_file>
    PASSWORD="$1"
    INPUT_FILE="$2"
  else
    # Case: Not enough arguments
    echo "Usage: pdf_dc [password] <input.pdf>"
    echo " If password is ommitted, it defaults to: $DEFAULT_PASSWORD"
    return 1
  fi
  ### --- Input Validation ---
  ## Check if the input file exists and is a regular file
  if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    return 1
  fi

  ### --- Output Setup and Check ---
  # Extract the base filename (e.g., "document" from "document.pdf"
  local BASENAME="${INPUT_FILE%.pdf}"

  # Construct the output filename
  OUTPUT_FILE="${BASENAME}_decrypted.pdf"

  # Prevent accidental overwrite
  if [ -f "$OUTPUT_FILE" ]; then
    echo "Error: Output file '$OUTPUT_FILE' already exists. Aborting to prevent accidental overwrite."
  fi

  ### --- execution ---
  echo "___"
  echo "Decrypting '$INPUT_FILE'..."
  printf "   Using password: %s\n" "$PASSWORD" # Safer use of printf
  echo "   Output file will be: $OUTPUT_FILE"
  echo "___"


  ## This assumes qpdf is already installed
  # Execute the qpdf command
  qpdf --password="$PASSWORD" --decrypt "$INPUT_FILE" "$OUTPUT_FILE"

  local EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then
    echo "Decrytion succesful: '$OUTPUT_FILE'"

  else
    echo "Decryption failed. qpdf exited with status $EXIT_CODE."
  fi
  return $EXIT_CIDE
}

