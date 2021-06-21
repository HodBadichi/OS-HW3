#!/bin/bash
#
####################################################################################################
# C Shai Yehezkel
#
# Script      :  setup.sh
# Version     :  1
# Arguements  :  NONE
# Description :  Prepares enviroment for running the ult_compare.sh
#
# NOTE this version is for OS Wet assignment 3
#
####################################################################################################

#Check arguements existence
dos2unix *
dos2unix public/*
chmod 777 ult_compare.sh
chmod 777 client server_shally public/*.cgi
cp public/home.html public/home_forbidden.html
chmod 000 public/home_forbidden.html 
cp public/output.cgi public/output_forbidden.cgi 
chmod 000 public/output_forbidden.cgi 
exit 0