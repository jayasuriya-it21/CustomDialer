package com.phone.dialer.di

import android.content.Context
import androidx.room.Room
import com.phone.dialer.data.calllog.CallLogRepository
import com.phone.dialer.data.calllog.CallLogRepositoryImpl
import com.phone.dialer.data.contacts.ContactRepository
import com.phone.dialer.data.contacts.ContactRepositoryImpl
import com.phone.dialer.data.db.AppDatabase
import com.phone.dialer.data.db.BlockedNumberDao
import com.phone.dialer.data.db.RecordingDao
import com.phone.dialer.data.recordings.RecordingRepository
import com.phone.dialer.data.recordings.RecordingRepositoryImpl
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideAppDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "phone_app_db"
        ).build()
    }

    @Provides
    fun provideRecordingDao(db: AppDatabase): RecordingDao = db.recordingDao()

    @Provides
    fun provideBlockedNumberDao(db: AppDatabase): BlockedNumberDao = db.blockedNumberDao()

    @Provides
    @Singleton
    fun provideContactRepository(
        @ApplicationContext context: Context
    ): ContactRepository = ContactRepositoryImpl(context)

    @Provides
    @Singleton
    fun provideCallLogRepository(
        @ApplicationContext context: Context
    ): CallLogRepository = CallLogRepositoryImpl(context)

    @Provides
    @Singleton
    fun provideRecordingRepository(
        recordingDao: RecordingDao
    ): RecordingRepository = RecordingRepositoryImpl(recordingDao)
}
