#! /bin/bash

# on OSX
#  brew install poppler ghostscript

# flatten pdf
# if second name is not given, original name + -fl suffix to name

output_infix="-fl"
cmd_pdftops="pdftops" # from poppler package
cmd_pstopdf="ps2pdf14" # from ghostscript package

input_file="$1"; shift
if [[ -z "$input_file" ]]; then
   echo "$0 filename.pdf [output.pdf]"
   exit 1
fi

if [[ -n "$1" ]]; then
  output_file="$1"; shift
else
  output_file=$(dirname $input_file)/$(basename $input_file .pdf)${output_infix}.pdf
fi

if [[ -f $output_file ]]; then
  echo $output_file exists.  rm it to proceed.
  exit 1
fi

$cmd_pdftops $input_file - | ps2pdf14 - $output_file
echo $output_file created
