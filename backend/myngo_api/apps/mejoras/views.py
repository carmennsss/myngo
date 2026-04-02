from django.shortcuts import render
from rest_framework import generics, filters, permissions
from rest_framework.views import APIView,status
from models import Voto
from serializers import VotoSerializer


class VotosCreate(generics.CreateAPIView):
    serializer_class = VotoSerializer
    permission_classes = [permissions.IsAuthenticated]
    
