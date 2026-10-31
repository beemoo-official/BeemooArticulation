from django.urls import path
from . import views

urlpatterns = [
    path("catalog/", views.CatalogView.as_view(), name="catalog"),
    path("activities/<slug:activity_id>/", views.ActivityConfigView.as_view(), name="activity-config"),
    path("stimuli/", views.StimulusListView.as_view(), name="stimulus-list"),
    path("flashcards/<slug:slug>/", views.FlashcardGroupView.as_view(), name="flashcard-group"),
]
