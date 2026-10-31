from django.db.models import Count, Q
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Child, Trial
from .serializers import TrialSerializer, ProgressSerializer


class TrialBatchView(APIView):
    """POST /api/v1/children/<id>/trials/ — batch trial upload."""

    def post(self, request, child_id):
        child = Child.objects.get(pk=child_id)
        serializer = TrialSerializer(
            data=request.data, many=True, context={"child": child}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"synced": len(serializer.data)}, status=status.HTTP_201_CREATED)


class ProgressView(APIView):
    """GET /api/v1/children/<id>/progress/?sound=s"""

    def get(self, request, child_id):
        trials = Trial.objects.filter(child_id=child_id)

        sound = request.query_params.get("sound")
        if sound:
            trials = trials.filter(activity_id__startswith=f"{sound}-sound-")

        # Group by activity
        from django.db.models import Count, Q, FloatField
        from django.db.models.functions import Cast

        results = (
            trials.values("activity_id", "level")
            .annotate(
                totalTrials=Count("id"),
                correctFirst=Count("id", filter=Q(first_attempt_outcome="correct")),
            )
            .order_by("activity_id")
        )

        data = []
        for r in results:
            total = r["totalTrials"]
            correct = r["correctFirst"]
            data.append({
                "activityId": r["activity_id"],
                "level": r["level"],
                "totalTrials": total,
                "correctFirst": correct,
                "accuracy": correct / total if total > 0 else 0.0,
            })

        serializer = ProgressSerializer(data, many=True)
        return Response(serializer.data)
