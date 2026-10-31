from django.urls import path
from . import views

urlpatterns = [
    path("children/<int:child_id>/trials/", views.TrialBatchView.as_view(), name="trial-batch"),
    path("children/<int:child_id>/progress/", views.ProgressView.as_view(), name="progress"),
]
