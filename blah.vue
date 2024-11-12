<template>
  <div>
    <!-- Date Range Pickers -->
    <v-row>
      <v-col cols="12" sm="6" md="4">
        <v-menu
          ref="startMenu"
          v-model="startMenu"
          :close-on-content-click="false"
          transition="scale-transition"
          offset-y
          min-width="auto"
        >
          <template v-slot:activator="{ on, attrs }">
            <v-text-field
              v-model="formattedStartDate"
              label="Start Date"
              prepend-icon="mdi-calendar"
              readonly
              v-bind="attrs"
              v-on="on"
            ></v-text-field>
          </template>
          <v-date-picker
            v-model="startDate"
            @input="startMenu = false"
            :max="endDate"
          ></v-date-picker>
        </v-menu>
      </v-col>
      <v-col cols="12" sm="6" md="4">
        <v-menu
          ref="endMenu"
          v-model="endMenu"
          :close-on-content-click="false"
          transition="scale-transition"
          offset-y
          min-width="auto"
        >
          <template v-slot:activator="{ on, attrs }">
            <v-text-field
              v-model="formattedEndDate"
              label="End Date"
              prepend-icon="mdi-calendar"
              readonly
              v-bind="attrs"
              v-on="on"
            ></v-text-field>
          </template>
          <v-date-picker
            v-model="endDate"
            @input="endMenu = false"
            :min="startDate"
          ></v-date-picker>
        </v-menu>
      </v-col>
      <!-- Export Button -->
      <v-col cols="12" sm="6" md="4">
        <v-btn color="primary" @click="exportToExcel">
          Export to Excel
        </v-btn>
      </v-col>
    </v-row>

    <!-- Search Input -->
    <v-text-field
      v-model="search"
      append-icon="mdi-magnify"
      label="Search"
      @input="onSearch"
      solo
    ></v-text-field>

    <!-- Data Table -->
    <v-data-table
      :headers="headers"
      :items="items"
      :options.sync="options"
      :server-items-length="totalItems"
      :loading="loading"
      :items-per-page="itemsPerPage"
      @update:options="onOptionsUpdate"
    >
      <template v-slot:item.summaryDate="{ item }">
        {{ formatDate(item.summaryDate) }}
      </template>
    </v-data-table>
  </div>
</template>

<script>
import axios from 'axios';
import { format } from 'date-fns';

export default {
  name: 'AggregateSummaryTable',
  data() {
    return {
      headers: [
        { text: 'Summary Date', value: 'summaryDate' },
        { text: 'Vessel Count', value: 'vesselCount' },
        { text: 'Indicator 1 Total', value: 'totalIndicator1' },
        { text: 'Indicator 2 Total', value: 'totalIndicator2' },
        { text: 'Indicator 3 Total', value: 'totalIndicator3' },
        { text: 'Total Submitted', value: 'totalSubmitted' },
        { text: 'Actioned', value: 'actioned' },
        { text: 'Not Actioned', value: 'notActioned' },
        {
          text: 'More Than One Submission',
          value: 'moreThanOneSubmission',
        },
        { text: 'Total Including Hidden', value: 'totalIncludingHidden' },
      ],
      items: [],
      totalItems: 0,
      options: {},
      search: '',
      loading: true,
      itemsPerPage: 10,
      startDate: null,
      endDate: null,
      startMenu: false,
      endMenu: false,
    };
  },
  computed: {
    formattedStartDate() {
      return this.startDate ? this.formatDate(this.startDate) : '';
    },
    formattedEndDate() {
      return this.endDate ? this.formatDate(this.endDate) : '';
    },
  },
  watch: {
    options: {
      handler() {
        this.fetchData();
      },
      deep: true,
    },
    startDate(val) {
      if (this.endDate && val > this.endDate) {
        this.endDate = null;
      }
      this.fetchData();
    },
    endDate(val) {
      if (this.startDate && val < this.startDate) {
        this.endDate = null;
      }
      this.fetchData();
    },
  },
  created() {
    this.fetchData();
  },
  methods: {
    fetchData() {
      this.loading = true;

      const { page, itemsPerPage, sortBy, sortDesc } = this.options;

      axios
        .get('/api/AggregateSummary', {
          params: {
            page: page || 1,
            itemsPerPage: itemsPerPage || this.itemsPerPage,
            sortBy: sortBy ? sortBy[0] : null,
            sortDesc: sortDesc ? sortDesc[0] : false,
            search: this.search,
            startDate: this.startDate,
            endDate: this.endDate,
          },
        })
        .then((response) => {
          this.items = response.data.items;
          this.totalItems = response.data.totalItems;
          this.loading = false;
        })
        .catch((error) => {
          console.error('Error fetching data:', error);
          this.loading = false;
        });
    },
    onOptionsUpdate() {
      this.fetchData();
    },
    onSearch() {
      this.fetchData();
    },
    exportToExcel() {
      // Build query parameters
      const params = new URLSearchParams();
      if (this.startDate) params.append('startDate', this.startDate);
      if (this.endDate) params.append('endDate', this.endDate);

      // Trigger file download
      window.location.href = `/api/AggregateSummary/ExportToExcel?${params.toString()}`;
    },
    formatDate(date) {
      return date ? format(new Date(date), 'yyyy-MM-dd') : '';
    },
  },
};
</script>

<style>
/* Add any custom styles here */
</style>
