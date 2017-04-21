from django.contrib import admin
from top.models import HashLog,KeywordLog

# Register your models here.

class KeywordLogAdmin(admin.ModelAdmin):
    list_display = ('log_time', 'keyword', 'ip')

class HashLogAdmin(admin.ModelAdmin):
	list_display = ('log_time', 'hash_id', 'ip')

admin.site.register(KeywordLog, KeywordLogAdmin)
admin.site.register(HashLog, HashLogAdmin)
