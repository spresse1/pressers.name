from django.conf.urls import include, url

# Uncomment the next two lines to enable the admin:
from django.contrib import admin
admin.autodiscover()

urlpatterns = [
    # Examples:
    # url(r'^$', 'pressers_name.views.home', name='home'),
    # url(r'^pressers_name/', include('pressers_name.foo.urls')),

    # Uncomment the admin/doc line below to enable admin documentation:
    # url(r'^admin/doc/', include('django.contrib.admindocs.urls')),
    
    # Add djago-photologue for picture glleries
    url(r'^photos/', include('photologue.urls')),

    # Uncomment the next line to enable the admin:
    url(r'^admin/', include(admin.site.urls)),
    url(r'^', include('zinnia.urls')),
    #url(r'^comments/', include('django.contrib.comments.urls')),
    url(r'^comments/', include('django_comments.urls')),
]
