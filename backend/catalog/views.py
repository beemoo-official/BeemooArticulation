from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Umbrella, Activity, Stimulus, FlashcardGroup
from .serializers import (
    CatalogSerializer,
    ActivityConfigSerializer,
    StimulusSerializer,
    FlashcardGroupSerializer,
)


class CatalogView(APIView):
    """GET /api/v1/catalog/ — full catalog."""

    def get(self, request):
        data = {
            "version": 1,
            "umbrellas": Umbrella.objects.all(),
            "activities": Activity.objects.select_related("umbrella").all(),
        }
        serializer = CatalogSerializer(data)
        return Response(serializer.data)


class ActivityConfigView(generics.RetrieveAPIView):
    """GET /api/v1/activities/<slug>/ — single activity config."""
    serializer_class = ActivityConfigSerializer
    lookup_field = "activity_id"
    queryset = Activity.objects.prefetch_related("screens").select_related("umbrella")


class StimulusListView(generics.ListAPIView):
    """GET /api/v1/stimuli/?sound=s&position=initial"""
    serializer_class = StimulusSerializer

    def get_queryset(self):
        qs = Stimulus.objects.all()
        sound = self.request.query_params.get("sound")
        position = self.request.query_params.get("position")
        if sound:
            qs = qs.filter(target_sound=sound)
        if position:
            qs = qs.filter(target_position=position)
        return qs


class FlashcardGroupView(generics.RetrieveAPIView):
    """GET /api/v1/flashcards/<slug>/"""
    serializer_class = FlashcardGroupSerializer
    lookup_field = "slug"
    queryset = FlashcardGroup.objects.all()
